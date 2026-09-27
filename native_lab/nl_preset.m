function c=nl_preset(name)
c=nl_defaults;
switch name
 case '07 RX-R417C: bốn mặt điện tử',c=nl_rx_preset('Search');return
 case '08 RX-R417C: vùng tập trung',c=nl_rx_preset('Focus');return
 case '01 Cơ bản: hai UAV',return
 case '02 Góc nhìn hẹp',c.radar.field_of_view_deg=[20 30];
 case '03 Báo giả và vật phản xạ'
  c.clutter.false_alarms=true;c.clutter.pfa=1e-5;c.clutter.scatterers_enabled=true;
  c.tracking.clutter_expected_per_update=10;
 case '04 Radar quét sector'
  c.radar.mode='Sector';c.radar.field_of_view_deg=[12 40];c.radar.scan_rate_deg_s=20;
  c.tracking.deletion_history=[8 12];
 case '05 UAV cơ động: IMM'
  c.method='GNN_IMM_EKF_SPH';c.uavs(1).waypoints_enu_m(3,:)=[1100 100 180];
 case '06 Mất phép đo: radar chậm'
  c.radar.update_every_steps=4;c.radar.detection_probability=.7;
 otherwise,error('Unknown preset.');
end
nl_validate(c);
end
