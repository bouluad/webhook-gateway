local cjson = require "cjson.safe"
local http = require "resty.http"
local hmac = ngx.hmac_sha256

-- 🔧 Webhook secret (shared with GitHub)
local secret = "your_webhook_secret"

-- 🧾 Read request body
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
    ngx.status = 401
    ngx.say("Missing signature header")
    return ngx.exit(401)
end

local computed_sig = "sha256=" .. ngx.encode_base16(hmac(secret, body)):lower()
if sig_header ~= computed_sig then
    ngx.status = 401
    ngx.say("Invalid signature")
    return ngx.exit(401)
end

-- 📦 Parse JSON payload
local payload = cjson.decode(body)
if not payload then
    ngx.status = 400
    ngx.say("Invalid JSON")
    return ngx.exit(400)
end

-- 🪶 Log information
local repo_name = payload.repository and payload.repository.full_name or "unknown"
local branch = payload.ref or "unknown"
local pusher = payload.pusher and payload.pusher.name or "unknown"

ngx.log(ngx.NOTICE, string.format(
    "Webhook validated: repo=%s, branch=%s, pusher=%s",
    repo_name, branch, pusher
))

-- ✅ Proxy to Jenkins
local httpc = http.new()
local res, err = httpc:request_uri(ngx.var.jenkins_url, {
    method = "POST",
    body = body,
    headers = {
        ["Content-Type"] = "application/json",
        ["X-GitHub-Event"] = ngx.var.http_x_github_event or "",
        ["X-Hub-Signature-256"] = sig_header
    },
})

if not res then
    ngx.status = 502
    ngx.say("Failed to forward to Jenkins: ", err)
    return ngx.exit(502)
end

ngx.status = res.status
ngx.say("Forwarded to Jenkins (", ngx.var.jenkins_url, ") with status ", res.status)
ngx.exit(res.status)
