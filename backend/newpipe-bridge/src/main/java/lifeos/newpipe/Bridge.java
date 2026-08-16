package lifeos.newpipe;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;

import org.schabi.newpipe.extractor.NewPipe;
import org.schabi.newpipe.extractor.ServiceList;
import org.schabi.newpipe.extractor.downloader.Downloader;
import org.schabi.newpipe.extractor.downloader.Request;
import org.schabi.newpipe.extractor.downloader.Response;
import org.schabi.newpipe.extractor.localization.ContentCountry;
import org.schabi.newpipe.extractor.localization.Localization;
import org.schabi.newpipe.extractor.search.SearchExtractor;
import org.schabi.newpipe.extractor.stream.StreamInfo;
import org.schabi.newpipe.extractor.stream.StreamInfoItem;
import org.schabi.newpipe.extractor.stream.StreamType;
import org.schabi.newpipe.extractor.stream.VideoStream;

import java.io.IOException;
import java.io.InputStream;
import java.net.InetSocketAddress;
import java.net.URI;
import java.net.URLDecoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.Executors;

/**
 * Minimal HTTP bridge over NewPipeExtractor for the LifeOS daemon.
 * Endpoints:
 *   POST /search   {"query": "..."} -> {"results":[{id,title,uploader,duration,thumbnail,live}]}
 *   GET  /streams  ?id=X            -> {id,title,uploader,thumbnail,duration,live,hls,mp4}
 *   GET  /health                    -> {"ok":true}
 * Binds to 127.0.0.1; only the local daemon should talk to it.
 */
public class Bridge {
    static final int DEFAULT_PORT = 18785;
    static final String UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36";

    public static void main(String[] args) throws Exception {
        int port = DEFAULT_PORT;
        for (int i = 0; i < args.length; i++) {
            if ("--port".equals(args[i]) && i + 1 < args.length) {
                port = Integer.parseInt(args[i + 1]);
            } else if ("--selftest".equals(args[i])) {
                System.exit(selftest());
            }
        }

        NewPipe.init(new SimpleDownloader(), new Localization("el", "GR"), new ContentCountry("GR"));

        HttpServer server = HttpServer.create(new InetSocketAddress("127.0.0.1", port), 0);
        server.createContext("/", Bridge::handle);
        server.setExecutor(Executors.newFixedThreadPool(4));
        server.start();
        System.out.println("newpipe-bridge listening on 127.0.0.1:" + port);
    }

    static void handle(HttpExchange ex) throws IOException {
        try {
            String path = ex.getRequestURI().getPath();
            String q = ex.getRequestURI().getRawQuery();
            switch (path) {
                case "/health" -> {
                    respond(ex, 200, "{\"ok\":true}");
                    return;
                }
                case "/search" -> {
                    if (!"POST".equals(ex.getRequestMethod())) {
                        respond(ex, 405, "{\"error\":\"POST required\"}");
                        return;
                    }
                    String body = new String(readAll(ex.getRequestBody()), StandardCharsets.UTF_8);
                    String query = extractQuery(body);
                    if (query.isEmpty()) {
                        respond(ex, 400, "{\"error\":\"missing query\"}");
                        return;
                    }
                    respond(ex, 200, doSearch(query));
                    return;
                }
                case "/streams" -> {
                    String id = queryParam(q, "id");
                    if (id.isEmpty()) {
                        respond(ex, 400, "{\"error\":\"missing id\"}");
                        return;
                    }
                    respond(ex, 200, doStreams(id));
                    return;
                }
                default -> respond(ex, 404, "{\"error\":\"not found\"}");
            }
        } catch (Exception e) {
            e.printStackTrace();
            respond(ex, 500, "{\"error\":" + esc(e.getMessage() == null ? "unknown" : e.getMessage()) + "}");
        }
    }

    static String doSearch(String query) throws Exception {
        SearchExtractor se = ServiceList.YouTube.getSearchExtractor(query);
        se.fetchPage();
        StringBuilder out = new StringBuilder("{\"results\":[");
        boolean first = true;
        for (var item : se.getInitialPage().getItems()) {
            if (!(item instanceof StreamInfoItem si)) {
                continue;
            }
            if (!first) out.append(',');
            first = false;
            out.append("{\"id\":\"").append(esc(videoId(si.getUrl())))
               .append("\",\"title\":\"").append(esc(si.getName()))
               .append("\",\"uploader\":\"").append(esc(si.getUploaderName()))
               .append("\",\"duration\":").append(si.getDuration())
               .append(",\"thumbnail\":\"").append(esc(firstImage(si.getThumbnails())))
               .append("\",\"live\":").append(si.getStreamType() == StreamType.LIVE_STREAM)
               .append('}');
        }
        out.append("]}");
        return out.toString();
    }

    static String doStreams(String id) throws Exception {
        StreamInfo info = StreamInfo.getInfo("https://www.youtube.com/watch?v=" + id);
        boolean live = info.getStreamType() == StreamType.LIVE_STREAM;
        StringBuilder out = new StringBuilder();
        out.append("{\"id\":\"").append(esc(id))
           .append("\",\"title\":\"").append(esc(info.getName()))
           .append("\",\"uploader\":\"").append(esc(info.getUploaderName()))
           .append("\",\"thumbnail\":\"").append(esc(firstImage(info.getThumbnails())))
           .append("\",\"duration\":").append(info.getDuration())
           .append(",\"live\":").append(live)
           .append(",\"hls\":\"").append(esc(live ? info.getHlsUrl() : ""))
           .append("\",\"mp4\":\"").append(esc(bestProgressive(info.getVideoStreams())))
           .append("\"}");
        return out.toString();
    }

    // Progressive mp4 (audio+video) with the highest resolution; live streams
    // usually expose none, so empty is fine there (hls is used instead).
    static String bestProgressive(List<VideoStream> streams) {
        VideoStream best = null;
        int bestRes = 0;
        for (VideoStream vs : streams) {
            if (vs.getResolution() == null) continue;
            String res = vs.getResolution().replaceAll("[^0-9]", "");
            int r = res.isEmpty() ? 0 : Integer.parseInt(res);
            if (r > bestRes) {
                bestRes = r;
                best = vs;
            }
        }
        return best == null ? "" : best.getUrl();
    }

    static String videoId(String url) {
        int i = url.indexOf("v=");
        if (i < 0) return url;
        int j = url.indexOf('&', i);
        return j < 0 ? url.substring(i + 2) : url.substring(i + 2, j);
    }

    static String firstImage(List<org.schabi.newpipe.extractor.Image> images) {
        return images == null || images.isEmpty() ? "" : images.get(0).getUrl();
    }

    static String extractQuery(String body) {
        int i = body.indexOf("\"query\"");
        if (i < 0) return "";
        int a = body.indexOf('"', i + 8);
        if (a < 0) return "";
        int b = body.indexOf('"', a + 1);
        if (b < 0) return "";
        return body.substring(a + 1, b);
    }

    static String queryParam(String rawQuery, String name) {
        if (rawQuery == null) return "";
        for (String pair : rawQuery.split("&")) {
            int i = pair.indexOf('=');
            if (i < 0) continue;
            String key = URLDecoder.decode(pair.substring(0, i), StandardCharsets.UTF_8);
            if (key.equals(name)) {
                return URLDecoder.decode(pair.substring(i + 1), StandardCharsets.UTF_8);
            }
        }
        return "";
    }

    static String esc(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", " ").replace("\r", " ");
    }

    static byte[] readAll(InputStream in) throws IOException {
        return in.readAllBytes();
    }

    static void respond(HttpExchange ex, int code, String body) throws IOException {
        byte[] bytes = body.getBytes(StandardCharsets.UTF_8);
        ex.getResponseHeaders().set("Content-Type", "application/json; charset=utf-8");
        ex.sendResponseHeaders(code, bytes.length);
        ex.getResponseBody().write(bytes);
        ex.close();
    }

    /**
     * NewPipeExtractor requires a Downloader implementation; only
     * {@link #execute(Request)} is abstract — the base get/post helpers route
     * through it.
     */
    static class SimpleDownloader extends Downloader {
        private final HttpClient client = HttpClient.newBuilder()
                .followRedirects(HttpClient.Redirect.NORMAL)
                .connectTimeout(Duration.ofSeconds(30))
                .build();

        @Override
        public Response execute(Request req) throws IOException {
            try {
                HttpRequest.Builder rb = HttpRequest.newBuilder(URI.create(req.url()))
                        .timeout(Duration.ofSeconds(120));
                boolean hasUa = false;
                for (Map.Entry<String, List<String>> e : req.headers().entrySet()) {
                    for (String v : e.getValue()) {
                        rb.header(e.getKey(), v);
                        if (e.getKey().equalsIgnoreCase("User-Agent")) hasUa = true;
                    }
                }
                if (!hasUa) rb.header("User-Agent", UA);
                byte[] data = req.dataToSend();
                switch (req.httpMethod()) {
                    case "HEAD" -> rb.method("HEAD", HttpRequest.BodyPublishers.noBody());
                    case "POST" -> rb.method("POST",
                            data == null ? HttpRequest.BodyPublishers.noBody()
                                    : HttpRequest.BodyPublishers.ofByteArray(data));
                    default -> rb.GET();
                }
                HttpResponse<String> res = client.send(rb.build(),
                        HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
                Map<String, List<String>> headers = new HashMap<>();
                res.headers().map().forEach((k, v) -> headers.put(k.toLowerCase(), v));
                return new Response(res.statusCode(), res.body() == null ? "" : "", headers,
                        res.body() == null ? "" : res.body(), res.uri().toString());
            } catch (InterruptedException ie) {
                Thread.currentThread().interrupt();
                throw new IOException(ie);
            }
        }
    }

    // ponytail: one runnable check — real search against YouTube; needs network.
    static int selftest() throws Exception {
        NewPipe.init(new SimpleDownloader(), new Localization("el", "GR"), new ContentCountry("GR"));
        String json = doSearch("test");
        int n = json.split("\"id\":\"").length - 1;
        System.out.println("SELFTEST OK: " + n + " results");
        return n > 0 ? 0 : 1;
    }
}