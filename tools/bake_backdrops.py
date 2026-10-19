"""Deterministically rasterize actual Hopán model triangles into tiny impostors.
Run the export_backdrop_models.gd tool first. Editable geometry remains in the
original landmark model kit. No photographs, image generation, runtime blur,
dynamic render-to-texture, lighting or model rendering is needed by the cards.
"""
from pathlib import Path
import json
import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'game/art/backdrops'

def bake(kind,source):
    p=np.array(source['vertices'],dtype=float)
    colors=np.array(source['colors'],dtype=float)
    normals=np.array(source['normals'],dtype=float)
    eye=np.array([.32,.08,-.944]);eye/=np.linalg.norm(eye)
    right=np.cross([0,1,0],eye);right/=np.linalg.norm(right)
    up=np.cross(eye,right)
    xy=np.column_stack((p@right,p@up))
    lo=xy.min(axis=0);hi=xy.max(axis=0)
    scale=124/max(hi-lo)
    screen=(xy-lo)*scale+2
    screen[:,1]=127-screen[:,1]
    depth=p@eye
    zbuffer=np.full((128,128),-np.inf)
    pixels=np.zeros((128,128,4),dtype=np.uint8)
    light=np.array([-.35,.8,-.5]);light/=np.linalg.norm(light)
    for start in range(0,len(p),3):
        a,b,c=screen[start:start+3]
        denom=(b[1]-c[1])*(a[0]-c[0])+(c[0]-b[0])*(a[1]-c[1])
        if abs(denom)<1e-8:continue
        low=np.maximum(np.floor(np.minimum(np.minimum(a,b),c)).astype(int),0)
        high=np.minimum(np.ceil(np.maximum(np.maximum(a,b),c)).astype(int),127)
        xs,ys=np.meshgrid(np.arange(low[0],high[0]+1)+.5,np.arange(low[1],high[1]+1)+.5)
        u=((b[1]-c[1])*(xs-c[0])+(c[0]-b[0])*(ys-c[1]))/denom
        v=((c[1]-a[1])*(xs-c[0])+(a[0]-c[0])*(ys-c[1]))/denom
        w=1-u-v
        z=u*depth[start]+v*depth[start+1]+w*depth[start+2]
        sl=np.s_[low[1]:high[1]+1,low[0]:high[0]+1]
        mask=(u>=0)&(v>=0)&(w>=0)&(z>zbuffer[sl])
        normal=normals[start:start+3].mean(axis=0)
        brightness=.68+.32*max(0,float(normal@light))
        rgb=np.clip(colors[start:start+3].mean(axis=0)*brightness,0,1)
        # A deliberately small palette and large texels survive giant scaling.
        rgb=np.round(rgb*23)/23
        pixels[sl][mask]=np.r_[np.rint(rgb*255).astype(np.uint8),255]
        zbuffer[sl][mask]=z[mask]
    image=Image.fromarray(pixels)
    bounds=image.getbbox()
    assert bounds is not None
    image=image.crop(bounds)
    OUT.mkdir(parents=True,exist_ok=True)
    image.save(OUT/f'{kind}.png')
    return dict(kind=kind,width=image.width,height=image.height,rgba_bytes=image.width*image.height*4,opaque_pixels=int(np.count_nonzero(np.asarray(image)[:,:,3])))

if __name__=='__main__':
    sources=json.loads((ROOT/'art-source/backdrops/models.json').read_text())
    metrics=[bake(kind,data) for kind,data in sources.items()]
    (ROOT/'art-source/backdrops/bake-metrics.json').write_text(json.dumps(metrics,indent=2)+'\n')
    print(json.dumps(metrics))
