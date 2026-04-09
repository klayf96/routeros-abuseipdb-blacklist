# routeros-abuseipdb-blacklist
AbuseIPDB APIv2 Blacklist Downloader for MikroTik RouterOS v7

## Guide for Standalone Scripts

### 🚀&nbsp; Features

- A standalone script that directly retrieves a list from AbuseIPDB, parses it, and adds the list.
  - Request a Blacklist from AbuseIPDB via APIv2.
  - Add the received blacklist (up to approximately 4,500-4,600 addresses) to the IP firewall address-list.
  - Does not rely on external parsing servers or third-party repositories. Everything is handled at the router.
  - All you need to do is sign up for AbuseIPDB and obtain an API key!
- IP version selection, Blacklist IP Truncation, minimum Confidence Score, and country filtering parameters can be configured.
- Written for RouterOS v7, no external parsing script is required.
  - It consists of simple code, so it runs smoothly even on low-end devices. (Tested on hAP ac lite)
  - Blacklists are downloaded to memory for processing and are not written to NAND.

<hr>

### 🔑&nbsp; Policies required for this script

- `read`, `write`, `test`

<hr>

### 🛠️&nbsp; Set required Variables

This script basically works by just entering the API key.

If necessary, you can adjust the options to suit your usage environment by referring to the information below.

#### `apiKey`

- Enter the API key for the AbuseIPDB account.

#### `timeout` (default: "3d 23:30:00")

- Sets the time for which added blacklisted addresses are valid.
- After this time elapses, addresses added to the firewall Address-list are removed.
- If you run the script daily, `3d 23:30:00` or `4d 23:30:00` is appropriate.
- If you run the script every two days, increase it to `5d 23:30`.

#### `getIPv4 or getIPv6` (default: getIPv4 `true`; getIPv6 `false`)

- Requests IPv4 or IPv6 blacklists from AbuseIPDB and adds them to the address-list of the `/ip firewall` or `/ipv6 firewall`
- If you set this value to false, it will not request the blacklist for that version.
- This script requests the list separately for each IP version.
  - Therefore, if you set both getIPv4 and getIPv6 to `true`, a total of two API requests will be executed.
  - AbuseIPDB's daily request limit is reset at 00:00 UTC.

#### `addrLimit4 or addrLimit6` (default: 0)

- Specifies the number of addresses to retrieve. (e.g., if you enter 1000, only 1000 addresses will be added.)
- This option is equivalent to the Blacklist IP Truncation parameter in AbuseIPDB APIv2
- If set to `0`, add the maximum number of addresses that can be retrieved. (Approximately 4500-4600 based on IPv4)

#### `confScore4 or confScore6` (default: 0)

- Specifies the minimum abuse confidence score for addresses to include in the blacklist.
- This feature is exclusive the AbuseIPDB subscribers (paid plans) and does not work on free plans.
- If you set this value to `0` or are using free plan, you will only receive addresses with a 100% Abuse Confidence Score.
  - this means that the only addresses with a very high probability of abuse will be included in the list.

#### `onCountry4 or onCountry6` (default: empty)

- Retrieves only the list of addresses for the specified country or countries.
- Only comma-separated lists of ISO 3166 alpha-2 codes are allowed. (e.g.: `US` or `US,MX,CA`)
- This feature is exclusive the AbuseIPDB subscribers (paid plans) and does not work on free plans.

#### `exCountry4 or exCountry6` (default: empty)

- Retrieves only the list excluding addresses for the specified country or countries.
- Only comma-separated lists of ISO 3166 alpha-2 codes are allowed. (e.g.: `US` or `US,MX,CA`)
- This feature is exclusive the AbuseIPDB subscribers (paid plans) and does not work on free plans.

<hr>

### 🧨&nbsp; Known Limitations

The number of addresses that can be retrieved with a single API request is approximately 4,500-4,600 (Based on IPv4).

- This is due to the variable size limit (64512 bytes) of the Fetch tool.
- If this size is exceeded, the last element of the parsed address array cannot be trusted because array elements are incompletely truncated.
- Therefore, the script measures the length of the returned data and discards the last element of the array if the value reaches the maximum size.
  - If fewer addresses are added than the value specified in `addrLimit4` or `addrLimit6`, It means that the specified number exceeds the size limit.
- The reason for choosing this approach is that verification via :toip or :toip6 was unreliable. (There is a possibility that incomplete addresses may be converted to addresses different from the actual addresses depending on where they are truncated.)

However, these limitations do not pose a significant problem due to the following characteristics.

- AbuseIPDB periodically returns a new blacklist. (Free plan: `daily`; Paid plan: `every hour`)
- If you run the script daily using the scheduler, new addresses (approximately 1,000–3,000) excluding duplicates are continuously added, resulting in a list of tens of thousands of addresses after a few days.
- The default timeout value is set short to keep the address list around 10,000, but extending this period allows you to maintain a much larger blacklist.

<hr>

### 🔑&nbsp; Applying AbuseIPDB Blacklist script via WinBox

#### 1. Copy the contents of `routeros-abuseipdb-blacklist.rsc` using [Copy raw file].

#### 2. Click `System - Scripts - New` on the left menu of WinBox.

#### 3. Please refer to the information below to set each item correctly:

- Enter `abuseipdb-blacklist` in the `Name` field.
- Select only `read`,`write`,`test` in the `Policy` field.
- Paste the copied code into the `Source` field.

#### 4. In the pasted code, insert your AbuseIPDB API key between the double quotes of the `apiKey`.

#### 5. Click `Apply` to save, then click `Run Script` to excute the script.

#### 6. If all settings are correct, the number of added addresses is recorded in the Log, and you can check the `blocklist_reported` list in the 'Address Lists' of each Firewall.

#### 7. Click `System - Scheduler - New` on the left menu of WinBox.

#### 8. Please refer to the information below to set each item correctly, then click `OK` or `Apply` to save.

- Enter `abuseipdb-blacklist` in the `Name` and `On Event` field.
- Select only `read`,`write`,`test` in the `Policy` field.
- Enter `1d 00:00:00` in the `Interval` field.
- Enter the time for the script to run automatically in the `Start Time` field.
  - To minimize the impact on throughput, early morning hours such as `02:30:00` are recommended.

<hr>

### 🛡️&nbsp; Using Added Blacklists

This script only adds a list of addresses to the firewall; to filter packets based on the `blocklist_reported` lists, you must create a drop rule in the `PREROUTING` chain of the `RAW` table.

Example of creating a rule to block all packets from blacklisted addresses on the WAN interface :

- IPv4 Firewall Rules
  - `/ip firewall raw add action=drop chain=prerouting comment="pf::drop blocklist addresses; BL; reported" in-interface-list=WAN log=no log-prefix="[PF] Activity blocked (BLr)" src-address-list=blocklist_reported`

- IPv6 Firewall Rules
  - `/ipv6 firewall raw add action=drop chain=prerouting comment="pf::drop blocklist addresses; BL; reported" in-interface-list=WAN log=no log-prefix="[PF] Activity blocked (BLr)" src-address-list=blocklist_reported`

<hr>

Ⓒ 2026 klayf (contact@klayf.com)
