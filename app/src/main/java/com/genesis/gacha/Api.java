package com.genesis.gacha;

import org.json.JSONObject;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.io.InputStream;

/** Session tokens are encrypted with Android Keystore. Gameplay state lives on the server. */
final class Api {
    static final Api INSTANCE = new Api();
    private String access = "", refresh = "";
    private long expires;
    private SessionStore store;
    synchronized void attach(android.content.Context context) { if(store!=null)return; store=new SessionStore(context); try { JSONObject saved=store.load(); if(saved!=null){access=saved.getString("access");refresh=saved.getString("refresh");expires=saved.getLong("expires");} } catch(Exception ex){clear();} }
    synchronized boolean signedIn() { return !access.isEmpty(); }
    synchronized void clear() { access = ""; refresh = ""; expires = 0; if(store!=null)store.clear(); }
    static boolean configured() {
        return BuildConfig.SUPABASE_URL.startsWith("https://") && !BuildConfig.SUPABASE_KEY.isEmpty();
    }
    synchronized boolean authenticate(String email, String password, boolean signup) throws Exception {
        JSONObject out = request(signup ? "/auth/v1/signup" : "/auth/v1/token?grant_type=password",
                new JSONObject().put("email", email).put("password", password), "");
        if (out.optString("access_token").isEmpty()) return false;
        session(out); return true;
    }
    private void session(JSONObject out) throws Exception {
        access = out.getString("access_token"); refresh = out.getString("refresh_token");
        expires = System.currentTimeMillis() + out.optLong("expires_in", 3600) * 1000L;
        if(store!=null)store.save(new JSONObject().put("access",access).put("refresh",refresh).put("expires",expires));
    }
    synchronized JSONObject rpc(String function, JSONObject args) throws Exception {
        if (access.isEmpty()) throw new Exception("Please sign in again.");
        if (System.currentTimeMillis() >= expires - 60000) {
            try { session(request("/auth/v1/token?grant_type=refresh_token", new JSONObject().put("refresh_token", refresh), "")); }
            catch (ApiError e) { if(e.status == 400 || e.status == 401) clear(); throw e; }
        }
        try { return request("/rest/v1/rpc/" + function, args, access); }
        catch (ApiError e) { if(e.status == 401) clear(); throw e; }
    }
    synchronized void logout() throws Exception {
        try { if(!access.isEmpty()) request("/auth/v1/logout", new JSONObject(), access); }
        finally { clear(); }
    }
    synchronized JSONObject get(String path) throws Exception { ensureSession();return transport(path,"GET",null,"application/json",access,false); }
    synchronized JSONObject upload(String path,byte[] bytes,String mime) throws Exception { ensureSession();return transport(path,"POST",bytes,mime,access,true); }
    synchronized JSONObject storage(String path,JSONObject args) throws Exception {ensureSession();return request(path,args,access);}
    private void ensureSession() throws Exception {if(access.isEmpty())throw new Exception("Please sign in again");if(System.currentTimeMillis()>=expires-60000){try{session(request("/auth/v1/token?grant_type=refresh_token",new JSONObject().put("refresh_token",refresh),""));}catch(ApiError e){if(e.status==400||e.status==401)clear();throw e;}}}
    private JSONObject request(String path, JSONObject data, String token) throws Exception {return transport(path,"POST",data.toString().getBytes(StandardCharsets.UTF_8),"application/json",token,false);}
    private JSONObject transport(String path,String method,byte[] bytes,String mime,String token,boolean upsert) throws Exception {
        if (!configured()) throw new Exception("Backend setup is required. See START-HERE.md in the project.");
        URL url = new URL(BuildConfig.SUPABASE_URL.replaceAll("/+$", "") + path);
        HttpURLConnection c = (HttpURLConnection)url.openConnection();
        try {
            c.setConnectTimeout(15000); c.setReadTimeout(20000); c.setInstanceFollowRedirects(false);
            c.setRequestMethod(method); c.setDoOutput(bytes!=null);
            c.setRequestProperty("apikey", BuildConfig.SUPABASE_KEY);
            c.setRequestProperty("Content-Type", mime);
            if(upsert)c.setRequestProperty("x-upsert","true");
            if (!token.isEmpty()) c.setRequestProperty("Authorization", "Bearer " + token);
            if(bytes!=null)try (java.io.OutputStream os = c.getOutputStream()) { os.write(bytes); }
            int code = c.getResponseCode();
            InputStream stream = code >= 200 && code < 300 ? c.getInputStream() : c.getErrorStream();
            String text = "";
            if (stream != null) {
                try (InputStream in = stream; java.io.ByteArrayOutputStream out = new java.io.ByteArrayOutputStream()) {
                    byte[] buffer = new byte[4096]; int n;
                    while((n=in.read(buffer))!=-1) out.write(buffer,0,n);
                    text = out.toString("UTF-8");
                }
            }
            JSONObject result;
            try { result = text.trim().startsWith("{") ? new JSONObject(text) : text.trim().startsWith("[") ? new JSONObject().put("items",new org.json.JSONArray(text)) : new JSONObject(); }
            catch(Exception ignored) { result = new JSONObject(); }
            if(code < 200 || code >= 300) throw new ApiError(code, result.optString("msg", result.optString("message", result.optString("error_description", "Request failed ("+code+"). Please try again."))));
            return result;
        } finally { c.disconnect(); }
    }
    static final class ApiError extends Exception {
        final int status;
        ApiError(int status,String message) { super(message); this.status=status; }
    }
}
