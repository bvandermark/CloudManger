# Invoke-RackAPI

This is a powershell tool built to automate large portions of working with the RACK API leaving you to focus on the objects you want to work with. It works by checking your Powershell Session for an Auth Token and Service Catalog. If it can't find either, it will prompt you for api credentials which it will use to generate a Token that gets stored in your Powershell session. If it does find a token, it will automatically validate your token and prompt you if your token is expired or going to expire in the next 5 minutes.

Usage is fairly simple is flexible enough to allow you to work with most parts of the Rackspace API:

```Powershell
Invoke-RackAPI -cloudRegion ORD -cloudService cloudServersOpenStack -filter /servers/detail
```