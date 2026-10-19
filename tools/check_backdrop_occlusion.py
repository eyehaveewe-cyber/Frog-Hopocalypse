"""Check a rendered gold cutout is hidden by the green foreground fixture."""
from pathlib import Path
import json
import numpy as np
from PIL import Image
root=Path(__file__).resolve().parents[1]/'docs/previews/backdrops'
a=np.array(Image.open(root/'occlusion-open.png').convert('RGB')).astype(float)
b=np.array(Image.open(root/'occlusion-foreground.png').convert('RGB')).astype(float)
mask=(a[:,:,0]>a[:,:,1]*1.05)&(a[:,:,1]>a[:,:,2]*1.05)&(b[:,:,1]>b[:,:,0]*1.12)&(b[:,:,1]>b[:,:,2]*1.05)
mask[:120]=False
mask[650:]=False
count=int(mask.sum())
assert count>100, f'Expected foreground to cover backdrop, found {count} pixels'
print(json.dumps({'gold_backdrop_pixels_replaced_by_foreground_green':count,'scope':'Paired fixed-camera 1280x900 browser fixture screenshots; colors and region are fixture-specific.'}))
