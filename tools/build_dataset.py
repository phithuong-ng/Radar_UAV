"""Reproducible target plots. Full suite: tools/build_suite.py."""
from pathlib import Path
import argparse, hashlib, io, json, os
import numpy as np
from scipy.io import loadmat, savemat
from scipy.interpolate import RegularGridInterpolator
from scipy.integrate import cumulative_trapezoid
ROOT = Path(__file__).resolve().parents[1]

def speed_at(t, tr):
    knots = np.array(tr['speed_times_s']); vals = np.array(tr['speed_values_mps'])
    j = np.clip(np.searchsorted(knots, t, side='right')-1, 0, len(knots)-2)
    u = np.clip((t-knots[j])/(knots[j+1]-knots[j]), 0, 1)
    w = u*u*u*(10-15*u+6*u*u)
    return vals[j]+(vals[j+1]-vals[j])*w

def curve(a, tr):
    rx, ry = tr['radius_x'], tr['radius_y']
    if tr['path'] == 'ellipse':
        xy = np.column_stack((rx*np.cos(a), ry*np.sin(a)))
        tangent = np.column_stack((-rx*np.sin(a), ry*np.cos(a)))
    elif tr['path'] == 'figure8':
        xy = np.column_stack((rx*np.sin(a), ry*np.sin(2*a)))
        tangent = np.column_stack((rx*np.cos(a), 2*ry*np.cos(2*a)))
    else:
        raise ValueError(tr['path'])
    return xy, tangent

def geometry(c, tr):
    t = np.arange(c['frames'])*c['dt']
    if tr['path'] == 'cv':
        velocity = np.asarray(tr['velocity'], dtype=float)
        elapsed = t-(tr['birth_scan']-1)*c['dt']
        p = np.asarray(tr['start'], dtype=float)+elapsed[:,None]*velocity
        return p, np.tile(velocity,(len(t),1)), np.zeros((len(t),3))
    # Integrate speed, then invert arc length. This bounds true speed even on ellipses/figure-8s.
    fine = np.unique(np.r_[np.arange(0, t[-1], .002), t, tr['speed_times_s']])
    length = cumulative_trapezoid(speed_at(fine, tr), fine, initial=0)
    distance = np.interp(t, fine, length)
    agrid = np.linspace(0, 2*np.pi, 40001)
    _, tangent = curve(agrid, tr)
    arc = cumulative_trapezoid(np.linalg.norm(tangent, axis=1), agrid, initial=0)
    phase = np.interp(tr['phase_rad'] % (2*np.pi), agrid, arc)
    angle = np.interp((distance+phase) % arc[-1], arc, agrid)
    xy, tangent = curve(angle, tr)
    center = np.asarray(tr['center'], dtype=float)
    p = np.tile(center, (len(t), 1)); p[:,:2] += xy
    v = np.zeros_like(p); v[:,:2] = tangent/np.linalg.norm(tangent,axis=1)[:,None]*speed_at(t,tr)[:,None]
    a = np.gradient(v, c['dt'], axis=0)
    return p, v, a

def polar(p, sensor):
    d = p-sensor
    return np.array([np.linalg.norm(d),np.arctan2(d[1],d[0]),np.arctan2(d[2],np.hypot(d[0],d[1]))])

def cart(z, sensor):
    r, az, el = z
    return sensor+r*np.array([np.cos(el)*np.cos(az),np.cos(el)*np.sin(az),np.sin(el)])

def snr_free(c, r, rcs):
    q = c['detection']
    reference = np.log(q['pfa_reference'])/np.log(q['reference_pd'])-1
    return reference*(rcs/q['reference_rcs_m2'])*(q['reference_range_m']/max(r,1))**4

def multipath_factor(c, p, sensor, ground, sensor_ground):
    m = c['multipath']
    if not m['enabled']:
        return 1.
    # Effective locally flat reflector, averaged over frequency and uncertain target height.
    # Models fading only. It does not create independent multipath ghost plots.
    horizontal = np.linalg.norm(p[:2]-sensor[:2])
    hr = max(sensor[2]-sensor_ground,.1); ht = max(p[2]-ground,.1)
    freq = np.linspace(m['frequency_hz']-m['bandwidth_hz']/2,m['frequency_hz']+m['bandwidth_hz']/2,9)
    heights = ht+np.linspace(-1,1,9)*m['height_uncertainty_m']
    direct = np.sqrt(horizontal**2+(heights-hr)**2)
    reflected = np.sqrt(horizontal**2+(heights+hr)**2)
    phase = 2*np.pi*freq[:,None]*(reflected-direct)[None,:]/299792458.
    factor = np.mean(np.abs(1+m['reflection_coefficient']*np.exp(-1j*phase))**4)
    return float(np.clip(factor,m['min_snr_factor'],m['max_snr_factor']))

def noise_sigma(c, snr):
    n = c['noise']; ref = snr_free(c,n['reference_range_m'],n['reference_rcs_m2'])
    sig = np.clip(np.array(n['reference_sigma'])*np.sqrt(ref/max(snr,1e-12)),n['floor_sigma'],n['ceiling_sigma'])
    sig[1:] = np.deg2rad(sig[1:])
    return sig

def report(c, k, time, xyz, sigma):
    r, az, el = polar(xyz,np.array(c['sensor_position']))
    J = np.array([[np.cos(el)*np.cos(az),-r*np.cos(el)*np.sin(az),-r*np.sin(el)*np.cos(az)],
                  [np.cos(el)*np.sin(az),r*np.cos(el)*np.cos(az),-r*np.sin(el)*np.sin(az)],
                  [np.sin(el),0,r*np.cos(el)]])
    R = J@np.diag(sigma**2)@J.T+np.eye(3)*1e-8
    return [k,time,*xyz,*R.flatten(order='F'),r,np.rad2deg(az),np.rad2deg(el),*sigma]

def generate(c):
    assert c['noise']['reported_covariance'] in ['matched','nominal']
    assert 0<c['detection']['reference_pd']<1 and 0<c['detection']['pfa_reference']<1
    assert c['dt']>0 and c['frames']>=2
    for tr in c['tracks']:
        assert tr['rcs_m2']>0 and np.all(np.diff(tr['speed_times_s'])>0)
        assert min(tr['speed_values_mps'])>=0 and max(tr['speed_values_mps'])<=c['speed_limit_mps']
        assert 1<=tr['birth_scan']<=tr['death_scan']<=c['frames']
    terrain = loadmat(ROOT/'data/dem/terrain.mat',squeeze_me=True)
    assert np.allclose(c['origin_lat_lon'],[terrain['origin_lat'],terrain['origin_lon']],rtol=0,atol=1e-8)
    gi = RegularGridInterpolator((terrain['north'],terrain['east']),terrain['terrain'],bounds_error=True)
    sensor = np.array(c['sensor_position'],float); bounds = np.array(c['bounds'],float)
    sensor_ground = float(gi([[sensor[1],sensor[0]]])[0])
    K = c['frames']; n = len(c['tracks']); ts = np.arange(K)*c['dt']; seed = c['seed']
    detection_draw = np.random.default_rng(np.random.SeedSequence([seed,1])).random((K,n))
    noise_draw = np.random.default_rng(np.random.SeedSequence([seed,2])).normal(size=(K,n,3))
    clutter_rng = np.random.default_rng(np.random.SeedSequence([seed,3]))
    shuffle_rng = np.random.default_rng(np.random.SeedSequence([seed,4]))
    paths = [geometry(c,tr) for tr in c['tracks']]
    truth=[]; rows=[]; labels=[]; oracle=[]; radar_truth=[]; stats=[]; report_snr=[]
    edges=np.array(c['clutter']['y_edges']); rates=np.array(c['clutter']['regional_rates'])
    assert len(edges)==len(rates)+1 and np.all(np.diff(edges)>0)
    for kk,time in enumerate(ts):
        k=kk+1; local=[]; labs=[]; ors=[]; snrs=[]; active=0; visible=0; delivered=0
        change=c['measurement_change']; disturbed=change['first_scan']<=k<=change['last_scan']
        factor=change['std_multiplier'] if disturbed else 1.
        for j,tr in enumerate(c['tracks']):
            if not tr['birth_scan']<=k<=tr['death_scan']:continue
            active+=1; p,v,a=[q[kk] for q in paths[j]]
            assert np.all(p>=bounds[:,0]) and np.all(p<=bounds[:,1])
            ground=float(gi([[p[1],p[0]]])[0]); assert p[2]>ground
            f=np.linspace(.01,.99,c['detection']['ray_samples'])
            ray=sensor+f[:,None]*(p-sensor)
            los=bool(np.all(ray[:,2]>gi(ray[:,[1,0]])+1)); visible+=los
            z=polar(p,sensor); mp=multipath_factor(c,p,sensor,ground,sensor_ground)
            snr=snr_free(c,z[0],tr['rcs_m2'])*mp
            pd=float(min(c['detection']['pd_ceiling'],np.exp(np.log(c['detection']['pfa_reference'])/(1+snr))))
            if c['detection']['terrain_los'] and not los:pd=0.
            sig0=noise_sigma(c,snr); sig=sig0*factor
            truth.append([k,time,tr['id'],*p,*v,p[2]-ground,int(los),pd,int(disturbed and factor!=1),np.linalg.norm(a)])
            radar_truth.append([k,tr['id'],tr['rcs_m2'],10*np.log10(tr['rcs_m2']),10*np.log10(snr),pd,mp,np.linalg.norm(v)])
            if detection_draw[kk,j]>=pd:continue
            delivered+=1; zz=z+noise_draw[kk,j]*sig
            assert zz[0]>0
            reported=sig if c['noise']['reported_covariance']=='matched' else sig0
            local.append(report(c,k,time,cart(zz,sensor),reported))
            labs.append([tr['id'],1,int(disturbed and factor!=1)]);ors.append([*sig,0,0,0]);snrs.append(10*np.log10(snr))
        counts=clutter_rng.poisson(rates)
        for region,count in enumerate(counts):
            lo=bounds[:,0].copy();hi=bounds[:,1].copy();lo[1]=edges[region];hi[1]=edges[region+1]
            for p in clutter_rng.uniform(lo,hi,(int(count),3)):
                # Same report-quality law at reference RCS; clutter has no true RCS.
                sig=noise_sigma(c,snr_free(c,np.linalg.norm(p-sensor),c['noise']['reference_rcs_m2']))*factor
                local.append(report(c,k,time,p,sig));labs.append([0,0,int(disturbed and factor!=1)]);ors.append([np.nan]*6);snrs.append(np.nan)
        order=shuffle_rng.permutation(len(local))
        rows.extend(local[j] for j in order); labels.extend(labs[j] for j in order);oracle.extend(ors[j] for j in order);report_snr.extend(snrs[j] for j in order)
        stats.append([k,active,visible,delivered,int(sum(counts)),0])
    return dict(truth=np.array(truth,float),detections=np.array(rows,float),labels=np.array(labels,float),
        oracle_noise_sigma_bias=np.array(oracle,float),radar_truth=np.array(radar_truth,float),report_snr_db=np.array(report_snr,float),scan_stats=np.array(stats,float),
        times=ts,dt=float(c['dt']),n_targets=float(n),lambda_clutter=float(sum(rates)),pd_nominal=.9,bounds=bounds,sensor_position=sensor,
        scenario=c['scenario'],seed=float(seed),reference_range_m=2500.,reference_elevation_deg=5.,config_json=json.dumps(c),
        truth_columns='scan,time,id,x,y,z,vx,vy,vz,agl,los,pd,disturbed,acceleration',
        radar_truth_columns='scan,id,rcs_m2,rcs_dbsm,snr_db,pd,multipath_snr_factor,speed_mps')

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--config',default=str(ROOT/'config/dataset_config.json'));ap.add_argument('--output',default=str(ROOT/'data/datasets'));ap.add_argument('--multipath',action='store_true');ap.add_argument('--seed',type=int);ap.add_argument('--force',action='store_true')
    args=ap.parse_args();c=json.loads(Path(args.config).read_text())
    if args.multipath:c['multipath']['enabled']=True
    if args.seed is not None:c['seed']=args.seed
    out=Path(args.output);out.mkdir(parents=True,exist_ok=True)
    name=f"{c['scenario']}_{c['seed']}.mat"; dest=out/name
    if dest.exists() and not args.force:raise FileExistsError('Choose a new output folder or explicitly pass --force')
    others=list(out.glob('*.mat'))
    if any(x.name!=name for x in others):raise ValueError('One-dataset folder required; choose a new output directory')
    d=generate(c); buf=io.BytesIO();savemat(buf,d,do_compression=True);data=buf.getvalue()
    tmp=dest.with_suffix('.partial');tmp.write_bytes(data);os.replace(tmp,dest)
    digest=hashlib.sha256(data).hexdigest();(out/'BUILD_ID.txt').write_text(digest+'\n')
    (out/'manifest.json').write_text(json.dumps([dict(file=name,sha256=digest,scenario=c['scenario'],seed=c['seed'],frames=c['frames'],reports=len(d['detections']))],indent=2))
    (out/'dataset_config.json').write_text(json.dumps(c,indent=2))
    print(f"Created {dest}: {len(d['truth'])} truth samples; {len(d['detections'])} reports; max speed {d['radar_truth'][:,7].max():.6f} m/s")
if __name__=='__main__':main()
