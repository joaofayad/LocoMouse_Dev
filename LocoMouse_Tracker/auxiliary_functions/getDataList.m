function data = DE_SwiStaDet_getDataList(tpath)

data = lsOSIndependent(tpath);
[tpath,~,~] = fileparts(tpath);
data = [repmat([tpath filesep],size(data,1),1) data];