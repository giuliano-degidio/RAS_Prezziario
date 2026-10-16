#!/usr/bin/env python3
import argparse, json, ssl, urllib.error, urllib.parse, urllib.request, uuid
from secrets_common import decrypt_payload
CLIENT_ID = str(uuid.uuid4())

def api_base(url):
    url=url.rstrip("/")
    return url if url.endswith("/nifi-api") else (url[:-5]+"/nifi-api" if url.endswith("/nifi") else url+"/nifi-api")
class Nifi:
    def __init__(self,cfg):
        self.base=api_base(cfg["base_url"]);self.ctx=ssl.create_default_context() if cfg["verify_ssl"] else ssl._create_unverified_context();self.token=""
        self.token=self.call("/access/token","POST",form={"username":cfg["username"],"password":cfg["password"]},raw=True).decode().strip()
    def call(self,path,method="GET",payload=None,form=None,raw=False):
        headers={};data=None
        if self.token: headers["Authorization"]="Bearer "+self.token
        if form is not None: data=urllib.parse.urlencode(form).encode();headers["Content-Type"]="application/x-www-form-urlencoded"
        elif payload is not None: data=json.dumps(payload).encode();headers["Content-Type"]="application/json"
        try:
            with urllib.request.urlopen(urllib.request.Request(self.base+path,data=data,method=method,headers=headers),context=self.ctx,timeout=60) as response: body=response.read()
        except urllib.error.HTTPError as exc: raise RuntimeError(f"{method} {path}: HTTP {exc.code} {exc.read().decode()}") from exc
        return body if raw else (json.loads(body) if body else {})
def flow(nifi,pg): return nifi.call(f"/flow/process-groups/{pg}").get("processGroupFlow",{}).get("flow",{})
def proc(nifi,pg,name,ptype,x,y,props,terminated):
    entity=nifi.call(f"/process-groups/{pg}/processors","POST",{"revision":{"clientId":CLIENT_ID,"version":0},"component":{"name":name,"type":ptype,"position":{"x":x,"y":y},"config":{"schedulingStrategy":"TIMER_DRIVEN","schedulingPeriod":"1 day","concurrentlySchedulableTaskCount":1,"properties":props,"autoTerminatedRelationships":terminated}}})
    return entity["component"]["id"]
def connect(nifi,pg,source,dest,relationship):
    nifi.call(f"/process-groups/{pg}/connections","POST",{"revision":{"clientId":CLIENT_ID,"version":0},"component":{"source":{"id":source,"type":"PROCESSOR","groupId":pg},"destination":{"id":dest,"type":"PROCESSOR","groupId":pg},"selectedRelationships":[relationship],"bends":[]}})
def verify_terminated(nifi,processor_id,relationship):
    component=nifi.call(f"/processors/{processor_id}")["component"]
    if relationship not in component.get("config",{}).get("autoTerminatedRelationships",[]):
        raise RuntimeError(f"{component['name']}: relationship {relationship} non auto-terminata")
def main():
    parser=argparse.ArgumentParser();parser.add_argument("--key-file",default="/opt/etl/secrets/fmr-secrets.key");parser.add_argument("--encrypted-config",default="/opt/etl/config/fmr-secrets.json.enc");args=parser.parse_args()
    nifi=Nifi(decrypt_payload(args.encrypted_config,args.key_file)["nifi"]);name="FRONTIERE_METADATA_RUNNER"
    if any(g.get("component",{}).get("name")==name for g in flow(nifi,"root").get("processGroups",[])): raise RuntimeError("Process Group gia esistente: eliminarlo prima del deploy")
    pg=nifi.call("/process-groups/root/process-groups","POST",{"revision":{"clientId":CLIENT_ID,"version":0},"component":{"name":name,"position":{"x":0,"y":0},"comments":"FMR v0.4 frontiere e refresh DWH chain 1"}})["component"]["id"]
    trigger=proc(nifi,pg,"Manual trigger","org.apache.nifi.processors.standard.GenerateFlowFile",0,0,{"Batch Size":"1","Data Format":"Text","Custom Text":"FMR manual trigger"},[])
    common={"Argument Delimiter":";","Working Directory":"/opt/etl/frontiere-metadata-runner","FMR_SECRET_KEY_FILE":"/opt/etl/secrets/fmr-secrets.key","FMR_ENCRYPTED_CONFIG":"/opt/etl/config/fmr-secrets.json.enc","FMR_LOG_DIR":"/opt/etl/log/frontiere-metadata-runner"}
    p1=proc(nifi,pg,"Run sequential full refresh","org.apache.nifi.processors.standard.ExecuteStreamCommand",300,0,{**common,"Command Path":"/opt/etl/frontiere-metadata-runner/.venv/bin/python","Command Arguments":"/opt/etl/frontiere-metadata-runner/scripts/run_frontiere.py","Ignore STDIN":"true"},["original"])
    p2=proc(nifi,pg,"Run DWH refresh chain 1","org.apache.nifi.processors.standard.ExecuteStreamCommand",650,0,{**common,"Command Path":"/opt/etl/frontiere-metadata-runner/.venv/bin/python","Command Arguments":"/opt/etl/frontiere-metadata-runner/scripts/run_dwh_refresh.py","Ignore STDIN":"false"},["original"])
    ok=proc(nifi,pg,"Log DWH refresh completed","org.apache.nifi.processors.standard.LogMessage",1000,-120,{"Log Level":"info","Log Message":"DWH refresh chain 1 completed"},["success"])
    ko1=proc(nifi,pg,"Log frontiere failed","org.apache.nifi.processors.standard.LogMessage",650,180,{"Log Level":"error","Log Message":"Frontiere failed; DWH refresh not started"},["success"])
    ko2=proc(nifi,pg,"Log DWH refresh failed","org.apache.nifi.processors.standard.LogMessage",1000,180,{"Log Level":"error","Log Message":"DWH refresh chain 1 failed"},["success"])
    connect(nifi,pg,trigger,p1,"success");connect(nifi,pg,p1,p2,"output stream");connect(nifi,pg,p1,ko1,"nonzero status");connect(nifi,pg,p2,ok,"output stream");connect(nifi,pg,p2,ko2,"nonzero status")
    verify_terminated(nifi,p1,"original");verify_terminated(nifi,p2,"original")
    print(f"[OK] Process Group creato STOPPED: {name} ({pg})")
    print("[OK] Frontiere -> DWH chain 1; original terminate=true su entrambi")
if __name__=="__main__": main()
