from fastapi import FastAPI, Request
from fastapi.responses import FileResponse, Response
import urllib.request, os
app=FastAPI()
FE=os.path.expanduser('~/Products/play/flutter/frontend')
BACKEND='http://127.0.0.1:8919'

# API代理优先(明确路径)
@app.api_route('/flutter/{path:path}', methods=['GET','POST'])
async def proxy(path:str, request:Request):
    body=await request.body()
    url=f'{BACKEND}/{path}'
    if request.url.query: url+=f'?{request.url.query}'
    req=urllib.request.Request(url, data=body if body else None, method=request.method,
        headers={'Content-Type':request.headers.get('content-type','application/json')})
    try:
        r=urllib.request.urlopen(req, timeout=300)
        return Response(content=r.read(), media_type=r.headers.get('content-type','application/json'))
    except urllib.error.HTTPError as e:
        return Response(content=e.read(), status_code=e.code, media_type='application/json')
    except Exception as e:
        return Response(content=str(e).encode(), status_code=500)

# 前端静态文件(显式,放proxy之后)
@app.get('/')
async def index(): return FileResponse(f'{FE}/index.html')
@app.get('/{path:path}')
async def static_files(path:str):
    fp=os.path.join(FE, path)
    if os.path.isfile(fp): return FileResponse(fp)
    return FileResponse(f'{FE}/index.html')
