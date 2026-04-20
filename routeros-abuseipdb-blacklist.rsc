# AbuseIPDB APIv2 Blacklist Downloader r2CL.06 for RouterOS v7
# (c) 2021-2023, 2026 klayf (contact@klayf.com)

######## Please edit below ########

:local apiKey ""
:local timeout "3d 23:30:00"

:local getIPv4      true
:local addrLimit4   0
:local confScore4   0
:local onCountry4   ""
:local exCountry4   ""

:local getIPv6      false
:local addrLimit6   0
:local confScore6   0
:local onCountry6   ""
:local exCountry6   ""

###################################

:local svcType  "AbuseIPDB"
:local head     ("[".$svcType." Blacklist] ")
:local errConn  ($head."The API key is incorrect, the daily request limit has been reached, or the server cannot be connected.")
:local errInv   ($head."The received list is empty; please check if the parameter settings are correct. (IPv")
:local finMesg  " addresses have been added to the list."
:local listName "blocklist_reported"
:local rawData
:local sizeList 0
:local addrList 0
:local endList 0
:global setData do={:return [/tool fetch mode=https http-method=get output=user http-header-field="Key: $aK, Accept: text/plain" url=($gU."ipVersion=".$ver) as-value]}
:global setList do={:return [:deserialize from=dsv delimiter="\n" options=dsv.plain value=$1]}
:global setURL do={
    :local apiURL   "https://api.abuseipdb.com/api/v2/blacklist\?"
    :if ($aL!=0) do={:set $apiURL ($apiURL."limit=".$aL."&")}
    :if ($cS!=0) do={:set $apiURL ($apiURL."confidenceMinimum=".$cS."&")}
    :if ([:len $oC]!=0) do={:set $apiURL ($apiURL."onlyCountries=".$oC."&")}
    :if ([:len $eC]!=0) do={:set $apiURL ($apiURL."exceptCountries=".$eC."&")}
    :return $apiURL
}

:do {
    :if ($getIPv4) do={
        :do {
            :local getURL [$setURL aL=$addrLimit4 cS=$confScore4 oC=$onCountry4 eC=$exCountry4]
            :set $rawData [$setData aK=$apiKey gU=$getURL ver="4"]
            :set $sizeList [:len ($rawData->"data")]
        } on-error={:error $errConn}
        :if ($sizeList!=0) do={
            :local countList 0
            :set addrList [$setList ($rawData->"data")]
            :if ($sizeList<64512) do={:set $endList ([:len $addrList]-1)} else={:set $endList ([:len $addrList]-2)}
            :for i from=0 to=($endList) do={[:do {/ip firewall address-list add list=$listName address=($addrList->$i) comment=("Provided by ".$svcType) timeout=$timeout}]; :set $countList ($countList+1)} on-error={}
            :log info ($head."(type: IPv4) - ".$countList.$finMesg)
        } else={:error ($errInv."4)")}
    }
    :if ($getIPv6) do={
        :do {
            :local getURL [$setURL aL=$addrLimit6 cS=$confScore6 oC=$onCountry6 eC=$exCountry6]
            :set $rawData [$setData aK=$apiKey gU=$getURL ver="6"]
            :set sizeList [:len ($rawData->"data")]
        } on-error={:error $errConn}
        :if ($sizeList!=0) do={
            :local countList 0
            :set addrList [$setList ($rawData->"data")]
            :if ($sizeList<64512) do={:set $endList ([:len $addrList]-1)} else={:set $endList ([:len $addrList]-2)}
            :for i from=0 to=($endList) do={[:do {/ipv6 firewall address-list add list=$listName address=($addrList->$i) comment=("Provided by ".$svcType) timeout=$timeout}]; :set $countList ($countList+1)} on-error={}
            :log info ($head."(type: IPv6) - ".$countList.$finMesg)
        } else={:error ($errInv."6)")}
    }
}
