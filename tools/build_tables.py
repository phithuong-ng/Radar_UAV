"""Exact numeric tables as editable HTML/SVG. Render SVG with Inkscape for PNG."""
import html, json, textwrap
from pathlib import Path
from PIL import ImageFont
from matplotlib.font_manager import findfont, FontProperties
ROOT=Path(__file__).resolve().parents[1];DOC=ROOT/'docs'
FONT=findfont(FontProperties(family='DejaVu Sans'))
BOLD=findfont(FontProperties(family='DejaVu Sans',weight='bold'))
def fmt(v,n=0):
    return f'{v:,.{n}f}'.replace(',','~').replace('.',',').replace('~','.')
def rng(a,b,n=2):return fmt(a,n) if abs(a-b)<1e-8 else fmt(a,n)+'–'+fmt(b,n)
def wrap(text,width,size,bold=False):
    font=ImageFont.truetype(BOLD if bold else FONT,size);out=[]
    for line in str(text).split('\n'):
        words=line.split();cur=''
        for word in words:
            candidate=(cur+' '+word).strip()
            if cur and font.getlength(candidate)>width:out.append(cur);cur=word
            else:cur=candidate
        out.append(cur)
    return out
class Page:
    def __init__(self,title):
        self.parts=['<svg xmlns="http://www.w3.org/2000/svg" width="1920" height="1080" viewBox="0 0 1920 1080"><rect width="1920" height="1080" fill="white"/>','<rect width="44" height="28" fill="#96caff"/><rect x="44" width="44" height="28" fill="#6398ff"/>']
        self.text(45,72,title,31,True)
    def text(self,x,y,txt,size=24,bold=False,color='#111'):
        self.parts.append(f'<text x="{x}" y="{y}" font-family="DejaVu Sans" font-size="{size}" font-weight="{"bold" if bold else "normal"}" fill="{color}">{html.escape(str(txt))}</text>')
    def table(self,x,y,widths,headers,rows,size=23,minheight=62):
        for ri,row in enumerate([headers]+rows):
            bold=ri==0;lines=[wrap(v,w-26,size,bold) for v,w in zip(row,widths)];height=max(minheight,max(map(len,lines))*(size+8)+20)
            xx=x
            for col,(w,ls) in enumerate(zip(widths,lines)):
                self.parts.append(f'<rect x="{xx}" y="{y}" width="{w}" height="{height}" fill="white" stroke="#656565" stroke-width="1.5"/>')
                yy=y+(height-len(ls)*(size+8))/2+size
                for line in ls:self.text(xx+13,yy,line,size,bold);yy+=size+8
                xx+=w
            y+=height
        return y
    def save(self,path):path.write_text(''.join(self.parts)+'</svg>',encoding='utf-8')
def htable(head,rows):
    return '<table><thead><tr>'+''.join('<th>'+html.escape(str(x)).replace('\n','<br>')+'</th>' for x in head)+'</tr></thead><tbody>'+''.join('<tr>'+''.join('<td>'+html.escape(str(x)).replace('\n','<br>')+'</td>' for x in row)+'</tr>' for row in rows)+'</tbody></table>'
def main():
    s=json.loads((DOC/'suite_summary.json').read_text());t=s['totals']
    overview=[['Kịch bản',8],['Seed/kịch bản',10],['Tổng số chuỗi đo',80],['Tổng scan',fmt(t['total_scans'])],['Truth sample',fmt(t['truth_samples'])],['Target detection',fmt(t['target_detections'])],['Clutter report',fmt(t['clutter_reports'])],['Tổng report',fmt(t['total_reports'])],['Pd quan sát',fmt(t['pd_observed'],4)]]
    desc={q['scenario']:q['description_vi'] for q in s['scenarios']}
    desc['joint_mismatch']='Cơ động + nhiễu đo ×4';desc['paper_style_3']='3 UAV khác RCS, biến thể mới';desc['measurement_only']='CV + nhiễu đo ×4';desc['regional_clutter']='Cơ động + nhiễu ×4 + clutter 5 vùng'
    cases=[[q['scenario'],desc[q['scenario']],10,160] for q in s['scenarios']]
    p=Page('BỘ DỮ LIỆU MÔ PHỎNG UAV / NỘI BÀI')
    p.table(45,115,[315,205],['Thành phần','Số lượng'],overview,size=25,minheight=69)
    p.table(610,115,[330,690,130,115],['Kịch bản','Nội dung','Số chuỗi đo','Scan/\nfile'],cases,size=24,minheight=75)
    p.text(610,880,'8 kịch bản × 10 seed = 80 file MAT đã sinh sẵn.',25,True)
    p.text(610,925,'Mỗi file: 160 scan, Δt = 0,64 s, thời lượng 101,76 s.',24)
    p.text(45,995,'Truth sample = một UAV tồn tại ở một scan. Pd quan sát = target detection / truth sample.',22)
    p.text(45,1035,'Số liệu đếm trực tiếp từ toàn bộ MAT v8.4. paper_style_3 không phải tái lập MI-GLMB.',21)
    p.save(DOC/'BANG_01_TONG_QUAN.svg')
    params=[['Vị trí radar','[0; −500; 12] m'],['Vùng giám sát','X [−3.000; 5.000] m\nY [−4.000; 2.000] m\nZ [20; 400] m'],['Chu kỳ đo','0,64 s'],['Pd','Theo RCS, cự ly, LOS\nTrần 0,98'],['Sai số cự ly*','σr = 5 m'],['Sai số phương vị*','σaz = 0,3°'],['Sai số góc tà*','σel = 0,5°'],['Clutter kỳ vọng','Đều: 25 plot/scan\n5 vùng: 125 plot/scan'],['Đa đường','Tắt mặc định\nCó tùy chọn sinh riêng']]
    uavs=[q for q in s['uav_parameters'] if q['scenario']=='motion_only']
    urows=[[q['uav'],fmt(q['rcs_m2'],3),fmt(q['rcs_dbsm'],2),rng(q['agl_min_m'],q['agl_max_m'],1)+' m',rng(q['range_min_m'],q['range_max_m'],1)+' m'] for q in uavs]
    velocities=[]
    labels=[('control_cv / measurement_only','control_cv'),('motion_only / joint_mismatch','motion_only'),('regional_clutter / dense_12','dense_12'),('fast_uav_mixed','fast_uav_mixed')]
    for label,key in labels:
        q=next(q for q in s['scenarios'] if q['scenario']==key)
        txt=rng(q['speed_min_mps'],q['speed_max_mps'],2)+' m/s'
        txt+='; có đoạn đứng yên' if q['speed_min_mps']==0 else '; CV từng UAV'
        velocities.append([label,txt])
    for q in [x for x in s['uav_parameters'] if x['scenario']=='paper_style_3']:
        velocities.append([f"paper_style_3 – UAV {q['uav']}",f"TB {fmt(q['speed_mean_mps'],2)}; max {fmt(q['speed_max_mps'],0)} m/s; có đứng yên"])
    p=Page('ĐIỀU KIỆN MÔ PHỎNG VÀ THÔNG SỐ UAV')
    p.table(45,120,[240,420],['Thông số','Giá trị'],params,size=24,minheight=66)
    p.text(765,112,'UAV trong kịch bản motion_only (seed 9100)',24,True)
    uy=p.table(765,135,[75,150,170,230,440],['UAV','RCS (m²)','RCS (dBsm)','Độ cao AGL','Cự ly tới radar'],urows,size=23,minheight=57)
    p.table(765,uy+28,[480,585],['Kịch bản','Vận tốc trong dữ liệu'],velocities,size=22,minheight=49)
    p.text(45,920,'*Tại RCS 0,01 m², cự ly 2 km.',22)
    p.text(45,955,'σ biến thiên theo SNR, có sàn/trần.',22)
    p.text(45,990,'Một số kịch bản nhân σ ×4 ở scan 45–75.',22)
    p.text(45,1032,'AGL = độ cao trên DSM tại vị trí UAV. Hệ Z dùng mốc DSM gốc. Mọi tham số là giả định mô phỏng.',21)
    p.save(DOC/'BANG_02_DIEU_KIEN.svg')
    css='body{font:16px Arial,sans-serif;margin:32px;color:#111}h1{font-size:27px}h2{font-size:21px;margin-top:30px}table{border-collapse:collapse;width:100%;margin:12px 0}td,th{border:1px solid #777;padding:10px;text-align:left}th{font-weight:bold}section{margin-bottom:48px}.grid{display:grid;grid-template-columns:32% 65%;gap:3%}.note{font-size:14px;color:#333}code{background:#eee;padding:2px}img{width:100%;max-width:1500px}@media print{section{break-after:page}.detail{break-after:auto}body{margin:15px}}'
    content='<!doctype html><html lang="vi"><meta charset="utf-8"><title>Bảng dataset Nội Bài v8.4</title><style>'+css+'</style><body>'
    content+='<section><h1>Bộ dữ liệu mô phỏng UAV / Nội Bài</h1><div class="grid"><div>'+htable(['Thành phần','Số lượng'],overview)+'</div><div>'+htable(['Kịch bản','Nội dung','Số chuỗi đo','Scan/file'],cases)+'</div></div><p>80 file đã sinh sẵn; 160 scan/file, 0,64 s/scan, 101,76 s/file. paper_style_3 là biến thể mới, không phải tái lập bài báo.</p><p class="note">Truth sample = một UAV tồn tại ở một scan. Các seed dùng cùng quỹ đạo trong mỗi kịch bản, ngẫu nhiên độc lập về detection, nhiễu và clutter. Các cặp đối chứng dùng cùng seed để so sánh.</p></section>'
    content+='<section><h1>Điều kiện mô phỏng và thông số UAV</h1><div class="grid"><div>'+htable(['Thông số','Giá trị'],params)+'<p>*Sigma tham chiếu tại 2 km, RCS 0,01 m²; biến thiên theo SNR và có sàn/trần. R báo đúng sigma đã sinh.</p></div><div><h2>UAV trong motion_only (seed 9100)</h2>'+htable(['UAV','RCS (m²)','RCS (dBsm)','Độ cao AGL','Cự ly tới radar'],urows)+htable(['Kịch bản','Vận tốc trong dữ liệu'],velocities)+'</div></div><p>AGL tính trên DSM tại vị trí UAV; Z theo mốc DSM gốc. Pd/RCS/SNR là mô hình giả định, chưa hiệu chuẩn radar thực.</p></section>'
    content+='<section class="detail"><h1>Thống kê từng kịch bản, toàn bộ 10 seed</h1>'+htable(['Kịch bản','Truth','Target detection','Clutter','Tổng report','Pd quan sát'],[[q['scenario'],fmt(q['truth_samples']),fmt(q['target_detections']),fmt(q['clutter_reports']),fmt(q['total_reports']),fmt(q['pd_observed'],4)] for q in s['scenarios']])+'</section>'
    for sc in s['scenarios']:
        rows=[]
        for q in [x for x in s['uav_parameters'] if x['scenario']==sc['scenario']]:
            rows.append([q['uav'],fmt(q['rcs_m2'],4),fmt(q['rcs_dbsm'],2),rng(q['agl_min_m'],q['agl_max_m'],2),rng(q['range_min_m'],q['range_max_m'],2),rng(q['speed_min_mps'],q['speed_max_mps'],2),fmt(q['speed_mean_mps'],2),fmt(q['longest_hover_s'],2),f"{q['birth_scan']}–{q['death_scan']}"])
        content+='<section class="detail"><h2>'+sc['scenario']+'</h2>'+htable(['UAV','RCS m²','dBsm','AGL m','Cự ly m','Vận tốc m/s','TB m/s','Đứng yên dài nhất s','Scan tồn tại'],rows)+'</section>'
    content+='<p>Số liệu: docs/suite_summary.json, tính trực tiếp từ 80 MAT. Khoảng đứng yên tính từ mẫu đầu đến mẫu cuối liên tiếp có tốc độ bằng 0. Chưa có kết quả tracker native MATLAB.</p></body></html>'
    (DOC/'BANG_DATASET.html').write_text(content,encoding='utf-8')
    print('Written editable HTML and 2 exact SVG tables.')
if __name__=='__main__':main()
