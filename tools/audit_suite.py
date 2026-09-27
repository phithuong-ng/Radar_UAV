"""Read every saved MAT, validate contracts, and export measured summary tables."""
from pathlib import Path
import csv, hashlib, json
import numpy as np
from scipy.io import loadmat
ROOT=Path(__file__).resolve().parents[1]

def runs(mask):
    edges=np.diff(np.r_[False,mask,False].astype(int));return list(zip(np.flatnonzero(edges==1),np.flatnonzero(edges==-1)))
def write_csv(path,rows):
    with path.open('w',newline='',encoding='utf-8-sig') as f:
        w=csv.DictWriter(f,fieldnames=rows[0].keys());w.writeheader();w.writerows(rows)
def main():
    folder=ROOT/'data/datasets';manifest=json.loads((folder/'manifest.json').read_text());suite=json.loads((ROOT/'config/suite_config.json').read_text())
    expected={f"{q['name']}_{s}.mat" for q in suite['cases'] for s in range(9100,9110)}
    assert len(manifest)==80 and {x['file'] for x in manifest}==expected
    assert {p.name for p in folder.glob('*.mat')}==expected
    records=[];tracks=[];all_checks=[]
    for entry in manifest:
        path=folder/entry['file'];assert hashlib.sha256(path.read_bytes()).hexdigest()==entry['sha256']
        d=loadmat(path,squeeze_me=True);c=json.loads(d['config_json']);t=d['truth'];z=d['detections'];l=d['labels'];v=np.linalg.norm(t[:,6:9],axis=1)
        checks=[]
        def check(name,ok):
            assert bool(ok),f'{path.name}: {name}'
            checks.append(name)
        check('160 increasing scan times',len(d['times'])==160 and np.allclose(np.diff(d['times']),.64))
        check('correct identity count',len(np.unique(t[:,2]))==entry['targets'])
        check('finite numeric truth/detections',np.isfinite(t).all() and np.isfinite(z).all())
        check('speed bounds',v.min()>=0 and v.max()<=150+1e-8)
        check('truth in bounds and above DSM',np.all(t[:,3:6]>=d['bounds'][:,0]) and np.all(t[:,3:6]<=d['bounds'][:,1]) and np.all(t[:,9]>0))
        check('all counts reconcile',np.array_equal(d['scan_stats'][:,3]+d['scan_stats'][:,4],np.bincount(z[:,0].astype(int),minlength=161)[1:]))
        check('truth unique per scan/id',len(np.unique(t[:,[0,2]],axis=0))==len(t))
        target=l[:,1]==1
        check('detections unique per scan/id',len(np.unique(np.column_stack([z[target,0],l[target,0]]),axis=0))==int(target.sum()))
        check('covariance positive definite',np.all(np.linalg.eigvalsh(z[:,5:14].reshape((-1,3,3)).transpose(0,2,1))>0))
        if c['noise']['reported_covariance']=='matched':check('actual sigma equals reported sigma',np.allclose(z[target,17:20],d['oracle_noise_sigma_bias'][target,:3]))
        maxhover=0;minhover=np.inf
        for tr in c['tracks']:
            a=t[t[:,2]==tr['id']];speed=np.linalg.norm(a[:,6:9],axis=1);rr=np.linalg.norm(a[:,3:6]-d['sensor_position'],axis=1)
            stops=runs(speed<1e-10);longest=max(((j-i-1)*c['dt'] for i,j in stops),default=0)
            maxhover=max(maxhover,longest);minhover=min(minhover,longest)
            check(f"UAV{tr['id']} displacement speed",np.max(np.linalg.norm(np.diff(a[:,3:6],axis=0),axis=1)/c['dt'])<=150+1e-5)
            if tr['path']!='cv':
                check(f"UAV{tr['id']} sustained hover",longest>=4.48-1e-9)
                for i,j in stops:check(f"UAV{tr['id']} constant hover position {i}",np.max(np.linalg.norm(a[i:j,3:6]-a[i,3:6],axis=1))<1e-7)
            else:check(f"UAV{tr['id']} exact CV",np.allclose(a[:,6:9],tr['velocity']) and np.all(a[:,13]==0))
            if entry['seed']==9100:
                tracks.append(dict(scenario=entry['scenario'],uav=tr['id'],rcs_m2=tr['rcs_m2'],rcs_dbsm=10*np.log10(tr['rcs_m2']),agl_min_m=a[:,9].min(),agl_max_m=a[:,9].max(),range_min_m=rr.min(),range_max_m=rr.max(),speed_min_mps=speed.min(),speed_max_mps=speed.max(),speed_mean_mps=speed.mean(),longest_hover_s=longest,birth_scan=tr['birth_scan'],death_scan=tr['death_scan']))
        rec=dict(file=path.name,scenario=entry['scenario'],seed=entry['seed'],split=entry['split'],frames=len(d['times']),targets=entry['targets'],truth_samples=len(t),target_detections=int(target.sum()),clutter_reports=int((~target).sum()),total_reports=len(z),pd_observed=float(target.sum()/len(t)),pd_expected=float(t[:,11].mean()),speed_min_mps=float(v.min()),speed_max_mps=float(v.max()),hover_truth_samples=int((v<1e-10).sum()),minimum_longest_hover_s=float(minhover),clutter_expected_per_scan=float(d['lambda_clutter']),los_fraction=float(t[:,10].mean()),checks=len(checks))
        records.append(rec);all_checks.append(dict(file=path.name,status='PASS',checks=checks))
    scenarios=[]
    for case in suite['cases']:
        group=[x for x in records if x['scenario']==case['name']];get=lambda k:sum(x[k] for x in group)
        scenarios.append(dict(scenario=case['name'],description_vi=case['description_vi'],files=len(group),frames_per_file=160,targets=case['targets'],total_scans=get('frames'),truth_samples=get('truth_samples'),target_detections=get('target_detections'),clutter_reports=get('clutter_reports'),total_reports=get('total_reports'),pd_observed=get('target_detections')/get('truth_samples'),speed_min_mps=min(x['speed_min_mps'] for x in group),speed_max_mps=max(x['speed_max_mps'] for x in group),clutter_expected_per_scan=group[0]['clutter_expected_per_scan'],noise_multiplier=case['noise_multiplier']))
    # Same seed supplies common random numbers for controlled noise comparisons.
    for left,right in [('control_cv','measurement_only'),('motion_only','joint_mismatch')]:
        a=loadmat(folder/f'{left}_9100.mat',squeeze_me=True);b=loadmat(folder/f'{right}_9100.mat',squeeze_me=True)
        assert np.array_equal(a['truth'][:,:12],b['truth'][:,:12])
        mask=(a['detections'][:,0]<45)|(a['detections'][:,0]>75)
        assert np.array_equal(a['detections'][mask],b['detections'][mask])
        assert not np.array_equal(a['detections'][~mask],b['detections'][~mask])
    get=lambda k:sum(x[k] for x in records)
    totals=dict(scenarios=8,seeds_per_scenario=10,files=80,total_scans=get('frames'),truth_samples=get('truth_samples'),target_detections=get('target_detections'),clutter_reports=get('clutter_reports'),total_reports=get('total_reports'),pd_observed=get('target_detections')/get('truth_samples'),speed_min_mps=min(x['speed_min_mps'] for x in records),speed_max_mps=max(x['speed_max_mps'] for x in records),hover_truth_samples=get('hover_truth_samples'),dt=.64,frames_per_file=160,duration_per_file_s=101.76)
    summary=dict(totals=totals,scenarios=scenarios,uav_parameters=tracks,files=records,native_matlab_executed=False)
    (ROOT/'docs/suite_summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2))
    (ROOT/'docs/full_validation.json').write_text(json.dumps(dict(status='PASS',files=80,checks=sum(x['checks'] for x in records),paired_comparisons=2,native_matlab_executed=False,details=all_checks),indent=2))
    write_csv(ROOT/'docs/all_file_statistics.csv',records);write_csv(ROOT/'docs/scenario_statistics.csv',scenarios);write_csv(ROOT/'docs/all_uav_parameters.csv',tracks)
    print(json.dumps(totals,indent=2));print('PASS:',sum(x['checks'] for x in records),'checks across 80 MAT files; MATLAB runtime not executed.')
if __name__=='__main__':main()
