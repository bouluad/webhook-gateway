local cjson = require "cjson.safe"
local hmac = ngx.hmac_sha256

-- 🔧 Config
local secret = "your_webhook_secret"
local jenkins_path = "/jenkins/github-webhook/"  -- Jenkins webhook endpoint

-- 🧾 Read body
ngx.req.read_body()
local body = ngx.req.get_body_data()
if not body then
    ngx.status = 400
    ngx.say("Missing body")
    return ngx.exit(400)
end

-- 🛡️ Validate signature
local sig_header = ngx.var.http_x_hub_signature_256
if not sig_header then
    ngx.status = 400
    ngx.say("Missing signature header")
    return ngx.exit(400)
end

local computed_sig = "sha256=" .. ngx.encode_base16(hmac(secret, body)):lower()
if sig_header ~= computed_sig then
    ngx.status = 403
    ngx.say("Invalid signature")
    return ngx.exit(403)
end

-- 📦 Parse JSON
local payload = cjson.decode(body)
if not payload then
    ngx.status = 400
    ngx.say("Invalid JSON")
    return ngx.exit(400)
end

-- 🪶 Extract and log info
local repo_name = payload.repository and payload.repository.name or "unknown"
local branch = payload.ref or "unknown"
local pusher = payload.pusher and payload.pusher.name or "unknown"

ngx.log(ngx.NOTICE, string.format(
    "Webhook received: repo=%s, branch=%s, pusher=%s",
    repo_name, branch, pusher
))

-- ✅ Proxy to Jenkins
return ngx.exec(jenkins_path)
