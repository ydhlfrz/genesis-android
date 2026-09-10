package com.genesis.gacha;

import org.junit.Test;
import static org.junit.Assert.*;
import org.json.JSONArray;
import org.json.JSONObject;
import java.io.ByteArrayOutputStream;
import java.io.FileInputStream;
import java.io.InputStream;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.util.Iterator;

public class CharacterEngineTest {
    private static String readUtf8(InputStream input) throws Exception {
        assertNotNull("Required test input is missing", input);
        try (InputStream in = input;
             ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            byte[] buffer = new byte[8192];
            int count;
            while ((count = in.read(buffer)) != -1) {
                out.write(buffer, 0, count);
            }
            return new String(out.toByteArray(), StandardCharsets.UTF_8);
        }
    }

    private static CharacterEngine loadEngine() throws Exception {
        return new CharacterEngine(readUtf8(
                new FileInputStream("src/main/assets/engine.js")));
    }

    // Compare JSON structurally. Object key order is irrelevant; array order matters.
    // Numeric representations such as 1 and 1.0 have the same JSON value.
    private static void assertJsonEqual(String path, Object expected, Object actual)
            throws Exception {
        if (expected == null || expected == JSONObject.NULL) {
            assertTrue(path + ": expected null", actual == null || actual == JSONObject.NULL);
        } else if (expected instanceof JSONObject) {
            assertTrue(path + ": expected object", actual instanceof JSONObject);
            JSONObject left = (JSONObject) expected;
            JSONObject right = (JSONObject) actual;
            assertEquals(path + ": object size", left.length(), right.length());
            Iterator<String> keys = left.keys();
            while (keys.hasNext()) {
                String key = keys.next();
                assertTrue(path + ": missing key " + key, right.has(key));
                assertJsonEqual(path + "." + key, left.get(key), right.get(key));
            }
        } else if (expected instanceof JSONArray) {
            assertTrue(path + ": expected array", actual instanceof JSONArray);
            JSONArray left = (JSONArray) expected;
            JSONArray right = (JSONArray) actual;
            assertEquals(path + ": array length", left.length(), right.length());
            for (int i = 0; i < left.length(); i++) {
                assertJsonEqual(path + "[" + i + "]", left.get(i), right.get(i));
            }
        } else if (expected instanceof Number) {
            assertTrue(path + ": expected number", actual instanceof Number);
            assertEquals(path + ": numeric value", 0,
                    new BigDecimal(expected.toString()).compareTo(
                            new BigDecimal(actual.toString())));
        } else {
            assertEquals(path, expected, actual);
        }
    }

    @Test public void interpreterMatchesWebCharacterFixtures() throws Exception {
        CharacterEngine engine = loadEngine();
        JSONArray fixtures = new JSONArray(readUtf8(
                getClass().getResourceAsStream("/fixtures.json")));
        assertEquals(100, fixtures.length());
        for (int i = 0; i < fixtures.length(); i++) {
            JSONObject fixture = fixtures.getJSONObject(i);
            String actual = engine.call("nativeReconstruct",
                    fixture.getJSONObject("row").toString());
            assertJsonEqual("Character fixture " + i,
                    fixture.getJSONObject("character"), new JSONObject(actual));
            assertEquals("Prompt mismatch at fixture " + i,
                    fixture.getString("prompt"), engine.call("nativePrompt", actual));
        }
    }

    @Test public void v2InterpreterMatchesNodeFixtures() throws Exception {
        CharacterEngine engine=loadEngine();
        JSONArray fixtures=new JSONArray(readUtf8(getClass().getResourceAsStream("/v2-fixtures.json")));
        assertEquals(25,fixtures.length());
        for(int i=0;i<fixtures.length();i++){
            JSONObject fixture=fixtures.getJSONObject(i);
            assertJsonEqual("V2 fixture "+i,fixture.getJSONObject("character"),new JSONObject(engine.call("nativeReconstruct",fixture.getJSONObject("row").toString())));
        }
    }

    @Test public void catalogHasExpectedCoverage() throws Exception {
        CharacterEngine engine = loadEngine();
        JSONObject catalog = new JSONObject(engine.call("nativeCatalog", ""));
        assertEquals(42, catalog.getJSONObject("data").getJSONArray("races").length());
        assertEquals(10, catalog.getJSONArray("rarities").length());
        JSONArray achievements = catalog.getJSONArray("achievements");
        assertEquals(47, achievements.length());
        int ap = 0;
        for (int i = 0; i < achievements.length(); i++) {
            ap += achievements.getJSONObject(i).getInt("ap");
        }
        assertEquals(940, ap);
    }
}
