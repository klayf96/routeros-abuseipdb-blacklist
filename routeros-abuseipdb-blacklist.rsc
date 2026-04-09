# AbuseIPDB APIv2 Blacklist Downloader r2CL.05 for RouterOS v7
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

:local srvType  "AbuseIPDB"
:local head     ("[".$srvType." Blacklist] ")
:local getURL   "https://api.abuseipdb.com/api/v2/blacklist\?"
:local errConn  ($head."The API key is incorrect, the daily request limit has been reached, or the server cannot be connected.")
:local errInv   ($head."The received list is empty; please check if the parameter settings are correct. (IPv")
:local finMesg  " addresses have been added to the list."
:local listName "blocklist_reported"
:local sizeList 0

:do {
    :if ($getIPv4) do={
        :local ver 4
        :local getURLv4 $getURL
        :local rawData
        :local addrList
        :local countList 0
        :do {
            :if ($addrLimit4!=0) do={:set getURLv4 ($getURLv4."limit=".$addrLimit4."&")}
            :if ($confScore4!=0) do={:set getURLv4 ($getURLv4."confidenceMinimum=".$confScore4."&")}
            :if ([:len $onCountry4]!=0) do={:set getURLv4 ($getURLv4."onlyCountries=".$onCountry4."&")}
            :if ([:len $exCountry4]!=0) do={:set getURLv4 ($getURLv4."exceptCountries=".$exCountry4."&")}
            :set rawData ([/tool fetch mode=https http-method=get output=user http-header-field="Key: $apiKey, Accept: text/plain" url=($getURLv4."ipVersion=$ver") as-value])
            :set sizeList [:len ($rawData->"data")]
        } on-error={:error $errConn}
        :if ($sizeList!=0) do={
            :local endList
            :set addrList [:deserialize from=dsv delimiter="\n" options=dsv.plain value=($rawData->"data")]
            :if ($sizeList<64512) do={:set $endList ([:len $addrList]-1)} else={:set $endList ([:len $addrList]-2)}
            :for i from=0 to=($endList) do={[:do {/ip firewall address-list add list=$listName address=($addrList->$i) comment=("Provided by ".$srvType) timeout=$timeout}]; :set $countList ($countList+1)} on-error={}
            :log info ($head."(type: IPv".$ver.") - ".$countList.$finMesg)
        } else={:error ($errInv.$ver.")")}
    }
    :if ($getIPv6) do={
        :local ver 6
        :local getURLv6 $getURL
        :local rawData
        :local addrList
        :local countList 0
        :do {
            :if ($addrLimit6!=0) do={:set getURLv6 ($getURLv6."limit=".$addrLimit6."&")}
            :if ($confScore6!=0) do={:set getURLv6 ($getURLv6."confidenceMinimum=".$confScore6."&")}
            :if ([:len $onCountry6]!=0) do={:set getURLv6 ($getURLv6."onlyCountries=".$onCountry6."&")}
            :if ([:len $exCountry6]!=0) do={:set getURLv6 ($getURLv6."exceptCountries=".$exCountry6."&")}
            :set rawData ([/tool fetch mode=https http-method=get output=user http-header-field="Key: $apiKey, Accept: text/plain" url=($getURLv6."ipVersion=$ver") as-value])
            :set sizeList [:len ($rawData->"data")]
        } on-error={:error $errConn}
        :if ($sizeList!=0) do={
            :local endList
            :set addrList [:deserialize from=dsv delimiter="\n" options=dsv.plain value=($rawData->"data")]
            :if ($sizeList<64512) do={:set $endList ([:len $addrList]-1)} else={:set $endList ([:len $addrList]-2)}
            :for i from=0 to=($endList) do={[:do {/ipv6 firewall address-list add list=$listName address=($addrList->$i) comment=("Provided by ".$srvType) timeout=$timeout}]; :set $countList ($countList+1)} on-error={}
            :log info ($head."(type: IPv".$ver.") - ".$countList.$finMesg)
        } else={:error ($errInv.$ver.")")}
    }
}
