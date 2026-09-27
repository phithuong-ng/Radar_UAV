"""Generate all configured scenarios/seeds, or one selected scenario.
Seed changes affect detection, measurement noise, clutter and shuffling, not trajectories.
"""
from pathlib import Path
import argparse, copy, hashlib, io, json, os
import numpy as np
from scipy.io import savemat
from build_dataset import ROOT, generate

def case_config(base, case, seed):
    c=copy.deepcopy(base);c['scenario']=case['name'];c['seed']=seed
    c['measurement_change']['std_multiplier']=case['noise_multiplier']
    tracks=copy.deepcopy(base['tracks'][:case['targets']])
    if case['motion']=='cv':
        starts=[[-2500,-3500,60],[4500,1500,100],[-2800,-1000,180],[4200,-500,220],[-2800,-2500,300],[-2500,-3800,350]]
        velocities=[[12,8,0],[-25,-15,0],[55,25,0],[-70,-35,0],[100,55,0],[120,90,0]]
        births=[1,1,1,10,1,20];deaths=[160,160,120,100,65,70]
        for j,tr in enumerate(tracks):
            v=float(np.linalg.norm(velocities[j]));tr.update(path='cv',start=starts[j],velocity=velocities[j],birth_scan=births[j],death_scan=deaths[j],speed_times_s=[0,101.76],speed_values_mps=[v,v],max_speed_mps=v)
    elif case['targets']==12:
        tracks=copy.deepcopy(base['tracks'][:6])
        for j,src in enumerate(base['tracks'][:6]):
            tr=copy.deepcopy(src);tr['id']=j+7;tr['phase_rad']+=1.7
            tr['center'][2]+=15;tr['rcs_m2']*=.8
            tr['birth_scan']=1+(j%3)*5;tr['death_scan']=160-(j%2)*5
            tracks.append(tr)
    c['tracks']=tracks
    if case['clutter']=='uniform':
        c['clutter']={'y_edges':[c['bounds'][1][0],c['bounds'][1][1]],'regional_rates':[25]}
    c['case_description_vi']=case['description_vi']
    c['trajectory_seed_policy']='Fixed geometry per scenario; independent stochastic measurements for each seed.'
    return c

def write_case(c,dest):
    d=generate(c);buf=io.BytesIO();savemat(buf,d,do_compression=True);data=buf.getvalue()
    tmp=dest.with_suffix('.partial');tmp.write_bytes(data);os.replace(tmp,dest)
    target=int((d['labels'][:,1]==1).sum());speed=np.linalg.norm(d['truth'][:,6:9],axis=1)
    return dict(file=dest.name,scenario=c['scenario'],seed=c['seed'],frames=c['frames'],targets=len(c['tracks']),sha256=hashlib.sha256(data).hexdigest(),truth_samples=len(d['truth']),target_detections=target,clutter_reports=len(d['detections'])-target,reports=len(d['detections']),speed_min_mps=float(speed.min()),speed_max_mps=float(speed.max()))

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--output',default=str(ROOT/'data/datasets'));ap.add_argument('--scenario');ap.add_argument('--seed',type=int);ap.add_argument('--force',action='store_true');ap.add_argument('--multipath',action='store_true');args=ap.parse_args()
    base=json.loads((ROOT/'config/dataset_config.json').read_text());suite=json.loads((ROOT/'config/suite_config.json').read_text())
    if args.multipath:base['multipath']['enabled']=True
    cases=[q for q in suite['cases'] if args.scenario is None or q['name']==args.scenario];assert cases,'Unknown scenario'
    seeds=[args.seed] if args.seed is not None else list(range(suite['seed_base'],suite['seed_base']+suite['seeds_per_scenario']))
    out=Path(args.output);out.mkdir(parents=True,exist_ok=True)
    expected={f"{q['name']}_{s}.mat" for q in cases for s in seeds}
    extras={p.name for p in out.glob('*.mat')}-expected
    if extras:raise ValueError('Output contains datasets outside this build. Choose a separate --output folder. No files deleted.')
    if not args.force and any((out/p).exists() for p in expected):raise FileExistsError('Use a fresh --output or --force to regenerate configured files')
    entries=[];total=len(expected)
    for q in cases:
        for seed in seeds:
            c=case_config(base,q,seed);entry=write_case(c,out/f"{q['name']}_{seed}.mat")
            entry['split']='tuning' if seed==suite['tuning_seed'] else ('validation' if seed in suite['validation_seeds'] else ('evaluation' if seed in suite['evaluation_seeds'] else 'custom'))
            entries.append(entry);print(f"{len(entries):02d}/{total}: {entry['file']} | {entry['reports']} reports",flush=True)
    encoded=json.dumps(entries,indent=2);(out/'manifest.json').write_text(encoded)
    (out/'BUILD_ID.txt').write_text(hashlib.sha256(encoded.encode()).hexdigest()+'\n')
    (out/'dataset_config.json').write_text(json.dumps(base,indent=2));(out/'suite_config.json').write_text(json.dumps(suite,ensure_ascii=False,indent=2))
    print(f"Complete: {len(entries)} MAT files, {sum(x['reports'] for x in entries)} reports",flush=True)
if __name__=='__main__':main()
