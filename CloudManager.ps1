function Set-APIDefaults{
    param(
        $userName=$null,
        $apiKey=$null,
        $apiRegion=$null,
        [ValidateSet("Clear","Set","List")]
        $action="List"
    )

    $ErrorActionPreference = "SilentlyContinue"

    if($action -eq "List"){
        $PSBoundParameters.userName = Get-Variable -Name userName -ValueOnly
        $PSBoundParameters.apiKey = Get-Variable -Name apiKey -ValueOnly
        $PSBoundParameters.apiRegion = Get-Variable -Name apiRegion -ValueOnly
    }
    $PSBoundParameters.Remove("action") | Out-Null
    $PSBoundParameters.Remove("verbose") | Out-Null
    foreach($param in $PSBoundParameters.Keys){
        $value = $PSBoundParameters.($param)
        switch($action){
            List{Get-Variable -Name $param -Scope Global}
            Set{Set-Variable -Name $param -Value $value -Scope Global -Verbose}
            Clear{Remove-Variable -Name $param -Verbose}
        }
    }
}
function Get-AuthServices {
    param(
        $userName,
        $apiKey
    )

    $identityURI = "https://identity.api.rackspacecloud.com/v2.0/tokens"
    $credJson = @{"auth" = @{"RAX-KSKEY:apiKeyCredentials" =  @{"username" = $userName; "apiKey" = $apiKey}}} | convertTo-Json
    $catalog = Invoke-RestMethod -Uri $identityURI -Method POST -Body $credJson -ContentType application/json
    $authToken = @{"X-Auth-Token"=$catalog.access.token.id}
    return $authToken,$catalog
}
function Get-ServiceCatalog{
    param(
        $cloudRegion=$null,
        $cloudService=$null,
        $serviceCatalog
    )
    
    $endpoints = ($serviceCatalog.access.servicecatalog | where name -eq $cloudService).endpoints
    if($endpoints.count -gt 1){
        Return ($endpoints | where region -eq $cloudRegion).publicURL
    }
    else{
        Return $endpoints.publicURL
    }
}
function CloudManager{
    param(
        [validateset("DFW","ORD","SYD","IAD","HKG")]
        $cloudRegion=$null,
        [validateset("cloudFilesCDN","cloudFiles","cloudBlockStorage","cloudImages","cloudQueues","cloudBigData","cloudOrchestration","cloudServersOpenStack","autoscale","cloudDatabases","cloudBackup","cloudNetworks","cloudMetrics","cloudLoadBalancers","cloudFeeds","cloudMonitoring","cloudDNS","rackCDN")]
        $cloudService=$null,
        $userName=$null,
        $apiKey=$null,
        $filter=$null,
        $body=$null,
        [validateset("Get","Post","Put","Delete")]
        $requestType
    )

    if($userName -eq $null){$userName = (Get-Variable userName -Scope Global).Value}
    if($apiKey -eq $null){$apiKey = (Get-Variable apiKey -Scope Global).Value}
    if($cloudRegion -eq $null){$cloudRegion = (Get-Variable apiRegion -Scope Global).Value}
    $AuthServices = Get-AuthServices -userName $userName -apiKey $apiKey
    $AuthToken = $AuthServices[0]
    $serviceCatalog = $AuthServices[1]
    $publicURL = Get-ServiceCatalog -cloudRegion $cloudRegion -cloudService $cloudService -serviceCatalog $serviceCatalog

    $workerURI = $publicURL + $filter
    if($body -ne $null){
        $body = $body | ConvertTo-Json -Depth 10
    }
    Invoke-RestMethod -Uri $workerURI -Method $requestType -Headers $AuthToken -Body $body -ContentType application/json
}