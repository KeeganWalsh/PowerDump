#Takes a HashTable of AppServers and puts them into groups for updating
#Edit as need be
FUNCTION Set-Group ([OBJECT]$AppServerList){
    IF($AppServerList.Length -le 4){
        [INT]$GroupCount = 1
    }ELSE{
        [INT]$GroupCount = ($AppServerList.Length / 4) + 1
    }
    IF(!($AppServerList.Length)){
        $Group0 =  @{};
        $Group0 |  % {$_.Add(($AppServerList.Name),(@{"Name" = ($AppServerList.Name); "Type" = (($AppServerList.Type))}))}
    }
    ELSE{$I = 0;$X = 0
        WHILE($X -le 3){
            IF($AppServerList[$I]){
                $DynamicName = "Group$X"
                FOR(NV -Name $DynamicName -Value @{};(GV $DynamicName -ValueOnly).count -lt $GroupCount -AND $AppServerList[$I];$I++){
                    GV $DynamicName -ValueOnly |  % {$_.Add(($AppServerList[$I].Name),(@{"Name" = ($AppServerList[$I].Name); "Type" = (($AppServerList[$I].Type))}))}
                }
            }
            $X++
        }
    }
    RV -Name "GroupCount"
    RETURN (GV "Group*")
}