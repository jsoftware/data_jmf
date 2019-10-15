NB. jmf memshare

NB. =========================================================
NB.*memshare v share memory with a process
NB.
NB. Form: {mapping-address} =: memshare {'share-name'} [; readonly ]
NB.
NB. this permits sharing memory with a non-J process
NB.
NB. memshare and memshareclose contributed by Tony Zackin
memshare=: 3 : 0
bNo_Inherit_Handle=. FALSE
'y ro'=. 2{.(boxopen y),<0
lpShareName=. y,{.a.
mh=. OpenFileMappingR (ro{FILE_MAP_WRITE,FILE_MAP_READ); bNo_Inherit_Handle; uucp lpShareName
('Unable to map ',y) assert mh~:0

addr=. MapViewOfFileR mh; (ro{FILE_MAP_WRITE,FILE_MAP_READ); 0; 0; 0
if. addr=0 do. 'MapViewOfFile failed' assert 0[CloseHandleR mh end.

NB. Add share-name to col. 1, mapping handle to col. 2, and mapping address to
NB. column 3 of mapTable:
".(_1=4!:0<'mapTable')#'mapTable=:i.0,3' 	NB. Create table if it doesn't already exist
mapTable=: mapTable, y; mh; addr			NB. y is share-name, mh is mapping handle
addr
)

NB. =========================================================
NB.*memshareclose v close memory shared with memshare
NB.
NB. Form: memshareclose {'share-name'}
memshareclose=: 3 : 0
NB. Get row containing map handle and address and assign to mh and addr respectively:
r=. y findkey mapTable						NB. Get the matching row(s) for the share-name
'Unknown share name' assert 0~:$r			NB. y not in column 0 of mapTable
'mh addr'=. {:(<r; 1 2){mapTable				NB. Get columns 1 & 2 values for the last matching row
('Unable to close share: ', y) assert $mh > 0
UnmapViewOfFileR <<addr						NB. Unmap the file view
if. CloseHandleR mh do. 					NB. If successful close then delete map table entry
  mapTable=: (<((i.#mapTable)-.r); i.{:$mapTable){mapTable 	NB. This supports the removal of one or more row(s)
end.                                        NB. which match the share-name
)
