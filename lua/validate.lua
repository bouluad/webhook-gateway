local cjson = require "cjson.safe"

-- === Configuration ===
local github_secret = os.getenv("GITHUB_WEBHOOK_SECRET") or "mySecretToken"

-- === Step 1: Read body ===
ngx.req.read_body()
local body = ngx.req.get_body_data()

if not body then
    ngx.status = 400
    ngx.say("Missing body")
    return ngx.exit(400)
end

-- === Step 2: Optional payload validation ===
local data = cjson.decode(body)
if not data or not data.repository then
    ngx.status = 400
    ngx.say("Invalid payload: missing repository")
    return ngx.exit(400)
end

-- Log info for observability
ngx.log(ngx.INFO, "Webhook received for repo: ", data.repository.name or "unknown",
        " targeting Jenkins: ", ngx.var.jenkins_url)

-- === Step 3: Forward to Jenkins via internal proxy ===
local res = ngx.location.capture("/proxy_to_jenkins", {
    method = ngx.HTTP_POST,
    body = body,
})

-- === Step 4: Handle Jenkins response ===
if not res then
    ngx.status = 500
    ngx.say("Internal proxy error")
    return ngx.exit(500)
end

if res.status >= 400 then
    ngx.status = res.status
    ngx.say("Jenkins returned error: ", res.body or "")
    return ngx.exit(res.status)
end

ngx.status = res.status
ngx.say("Webhook successfully forwarded to Jenkins (status: ", res.status, ")")
