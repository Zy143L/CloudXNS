module("luci.controller.cloudxns", package.seeall)

function index()
        entry({"admin", "network", "cloudxns"}, cbi("cloudxns"), _("CloudXNS DDNS"), 100)
end
