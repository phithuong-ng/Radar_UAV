"""Dataset/geometry/covariance checks. These are NOT MATLAB tracker execution tests."""
from pathlib import Path
import copy, csv, json
import numpy as np
from scipy.io import loadmat
from scipy.spatial.distance import cdist
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from build_dataset import generate, snr_free, noise_sigma
ROOT=Path(__file__).resolve().parents[1]

def temporal_indices(d,config):
    z=d['detections'];times=d['times'];K=len(times);indices=[]
    for kk in range(K):
        k=kk+1;ii=np.flatnonzero(z[:,0]==k);cur=z[ii];yes=np.ones(len(ii),bool)
        if config['enabled'] and kk>0:
            yes[:]=False
            for lag in range(1,min(config['max_lag_scans'],kk)+1):
                prev=z[z[:,0]==k-lag]
                if not len(prev):continue
                for i in range(len(cur)):
                    if yes[i]:continue
                    delta=prev[:,2:5]-cur[i,2:5];dist=np.linalg.norm(delta,axis=1);u=delta/np.maximum(dist[:,None],np.finfo(float).eps)
                    Ri=cur[i,5:14].reshape((3,3),order='F');Rj=prev[:,5:14].reshape((-1,3,3)).transpose(0,2,1)
                    var=np.einsum('ni,nij,nj->n',u,Rj+Ri,u)
                    yes[i]=np.any(dist<=config['speed_limit_mps']*(times[kk]-times[kk-lag])+config['sigma_gate']*np.sqrt(np.maximum(var,0)))
        indices.extend(ii[yes])
    return np.array(indices,int)

def runs(mask):
    changes=np.diff(np.r_[False,mask,False].astype(int));return list(zip(np.flatnonzero(changes==1),np.flatnonzero(changes==-1)))

def main():
    files=[ROOT/'data/datasets/fast_uav_mixed_9100.mat'];assert files[0].is_file()
    d=loadmat(files[0],squeeze_me=True);c=json.loads(d['config_json']);tc=json.loads((ROOT/'config/tracker_config.json').read_text())
    t=d['truth'];z=d['detections'];l=d['labels'];rt=d['radar_truth'];speed=np.linalg.norm(t[:,6:9],axis=1)
    checks=[]
    def check(name,condition):
        assert bool(condition),name
        checks.append(dict(check=name,status='PASS'))
    check('160 scans, 7 UAV identities',len(d['times'])==160 and len(np.unique(t[:,2]))==7)
    check('Actual speed range 0..150 m/s',speed.min()==0 and abs(speed.max()-150)<1e-9 and np.all(speed<=150+1e-9))
    check('Every XYZ above DSM',np.all(t[:,9]>0))
    check('Counts agree',np.array_equal(d['scan_stats'][:,3]+d['scan_stats'][:,4],np.bincount(z[:,0].astype(int),minlength=161)[1:]))
    tracks=[]
    for tr in c['tracks']:
        a=t[t[:,2]==tr['id']];v=np.linalg.norm(a[:,6:9],axis=1);stop=runs(v<1e-10)
        longest=max((j-i for i,j in stop),default=0)
        check(f"UAV {tr['id']}: continuous hover >=8 scans",longest>=8)
        for i,j in stop:
            check(f"UAV {tr['id']}: fixed position during hover {int(a[i,0])}",np.max(np.linalg.norm(a[i:j,3:6]-a[i,3:6],axis=1))<1e-7)
        check(f"UAV {tr['id']}: displacement speed <=150",np.max(np.linalg.norm(np.diff(a[:,3:6],axis=0),axis=1)/c['dt'])<=150+1e-5)
        rr=np.linalg.norm(a[:,3:6]-d['sensor_position'],axis=1)
        tracks.append(dict(uav=tr['id'],rcs_m2=tr['rcs_m2'],rcs_dbsm=10*np.log10(tr['rcs_m2']),speed_min_mps=v.min(),speed_max_mps=v.max(),speed_mean_mps=v.mean(),agl_min_m=a[:,9].min(),agl_max_m=a[:,9].max(),range_min_m=rr.min(),range_max_m=rr.max(),hover_scan_ranges='; '.join(f'{int(a[i,0])}-{int(a[j-1,0])}' for i,j in stop),longest_hover_s=(longest-1)*c['dt']))
    R=z[:,5:14].reshape((-1,3,3)).transpose(0,2,1)
    check('Reported Cartesian covariances positive definite',np.all(np.linalg.eigvalsh(R)>0))
    target=l[:,1]==1
    check('Actual sigma matches reported target sigma',np.allclose(d['oracle_noise_sigma_bias'][target,:3],z[target,17:20]))
    lookup={(r[0],r[2]):r for r in t};a=np.array([lookup[(row[0],lab[0])] for row,lab in zip(z[target],l[target])]);e=z[target,2:5]-a[:,3:6]
    rel=a[:,3:6]-d['sensor_position'];truthpolar=np.column_stack([np.linalg.norm(rel,axis=1),np.arctan2(rel[:,1],rel[:,0]),np.arctan2(rel[:,2],np.linalg.norm(rel[:,:2],axis=1))])
    residual=np.column_stack([z[target,14],np.deg2rad(z[target,15:17])])-truthpolar
    residual[:,1]=(residual[:,1]+np.pi)%(2*np.pi)-np.pi
    standardized=residual/d['oracle_noise_sigma_bias'][target,:3]
    check('Noise draws have plausible standardized mean/std',np.all(np.abs(standardized.mean(axis=0))<.15) and np.all(np.abs(standardized.std(axis=0)-1)<.15))
    regenerated=generate(c)
    for key in ['truth','detections','labels','radar_truth']:
        check('Reproducible numeric '+key,np.array_equal(regenerated[key],d[key],equal_nan=True))
    mp=copy.deepcopy(c);mp['multipath']['enabled']=True;dm=generate(mp)
    check('Multipath preserves trajectories',np.array_equal(dm['truth'][:,:11],t[:,:11]))
    check('Multipath modifies SNR/Pd',np.any(np.abs(dm['radar_truth'][:,4]-rt[:,4])>.01) and np.any(np.abs(dm['radar_truth'][:,5]-rt[:,5])>1e-5))
    check('RCS raises SNR and lowers uncertainty',snr_free(c,3000,.02)>snr_free(c,3000,.004) and np.all(noise_sigma(c,snr_free(c,3000,.02))<=noise_sigma(c,snr_free(c,3000,.004))))
    keep=temporal_indices(d,tc['temporal_support']);retained_targets=int(target[keep].sum());retained_clutter=int((~target[keep]).sum())
    check('Temporal support retains >=98 percent target detections',retained_targets/target.sum()>=.98)
    check('Temporal support reduces clutter',retained_clutter<(~target).sum())
    # Causality: altering future reports cannot change the prefix selections.
    prefix=copy.copy(d);prefix['times']=d['times'][:100];prefix['detections']=z[z[:,0]<=100]
    pk=temporal_indices(prefix,tc['temporal_support'])
    check('Temporal support is prefix-causal',np.array_equal(pk,keep[z[keep,0]<=100]))
    phases={}
    for value,name in [(0,'nominal'),(1,'sigma_x4')]:
        m=l[target,2]==value;phases[name]=dict(count=int(m.sum()),plot_rmse_3d_m=float(np.sqrt(np.mean(np.sum(e[m]**2,axis=1)))))
    summary=dict(dataset=files[0].name,frames=160,dt=c['dt'],duration_s=float(d['times'][-1]),targets=7,truth_samples=len(t),target_detections=int(target.sum()),clutter_reports=int((~target).sum()),total_reports=len(z),pd_observed=float(target.sum()/len(t)),pd_expected=float(t[:,11].mean()),speed_min_mps=float(speed.min()),speed_max_mps=float(speed.max()),accel_max_mps2=float(t[:,13].max()),hover_truth_samples=int((speed<1e-10).sum()),los_fraction=float(t[:,10].mean()),temporal_support=dict(raw=len(z),kept=len(keep),target_retention=retained_targets/int(target.sum()),clutter_retained=retained_clutter,clutter_removed_fraction=1-retained_clutter/int((~target).sum())),measurement_phases=phases,tracks=tracks)
    (ROOT/'docs/dataset_summary.json').write_text(json.dumps(summary,indent=2))
    with (ROOT/'docs/uav_parameters.csv').open('w',newline='',encoding='utf-8-sig') as f:
        w=csv.DictWriter(f,fieldnames=tracks[0].keys());w.writeheader();w.writerows(tracks)
    (ROOT/'docs/python_validation.json').write_text(json.dumps(dict(status='PASS',checks=checks,native_matlab_executed=False,scope='Dataset and numerical contracts only; no native tracker scores generated'),indent=2))
    fig,axes=plt.subplots(2,2,figsize=(13,8));colors=plt.cm.tab10.colors
    for i,tr in enumerate(c['tracks']):
        a=t[t[:,2]==tr['id']];v=np.linalg.norm(a[:,6:9],axis=1)
        axes[0,0].plot(a[:,1],v,label=f"UAV {tr['id']}",color=colors[i]);axes[0,1].plot(a[:,3],a[:,4],color=colors[i])
    axes[0,0].set(xlabel='Time (s)',ylabel='Speed (m/s)',ylim=(-3,155),title='0–150 m/s with sustained hover');axes[0,0].legend(ncol=4,fontsize=8)
    axes[0,1].plot(d['sensor_position'][0],d['sensor_position'][1],'k*',ms=12);axes[0,1].set(xlabel='East (m)',ylabel='North (m)',title='Mixed trajectories');axes[0,1].axis('equal')
    axes[1,0].plot(d['times'],d['scan_stats'][:,1],label='Truth');axes[1,0].plot(d['times'],d['scan_stats'][:,3],label='Detected UAVs');axes[1,0].set(xlabel='Time (s)',ylabel='UAV count',title='Detection probability depends on RCS/range');axes[1,0].legend()
    raw=np.bincount(z[:,0].astype(int),minlength=161)[1:];kept=np.bincount(z[keep,0].astype(int),minlength=161)[1:]
    axes[1,1].plot(d['times'],raw,label='Raw reports');axes[1,1].plot(d['times'],kept,label='Causal temporal support');axes[1,1].set(xlabel='Time (s)',ylabel='Reports/scan',title='Same retained detections for all methods');axes[1,1].legend()
    for ax in axes.flat:ax.grid(alpha=.25)
    fig.tight_layout();fig.savefig(ROOT/'docs/dataset_overview.png',dpi=150);plt.close(fig)
    print(json.dumps({k:v for k,v in summary.items() if k!='tracks'},indent=2));print(f'{len(checks)} dataset checks PASS; native MATLAB not run.')
if __name__=='__main__':main()
