package com.genesis.gacha;
import org.junit.Test;
import static org.junit.Assert.*;
import org.json.*;
import java.nio.file.*;
import java.nio.charset.StandardCharsets;
import java.io.InputStream;
public class CharacterEngineTest {
 @Test public void interpreterMatchesWebCharacterFixtures() throws Exception {
  CharacterEngine engine=new CharacterEngine(Files.readString(Path.of("src/main/assets/engine.js")));
  String content;try(InputStream in=getClass().getResourceAsStream("/fixtures.json")){assertNotNull(in);content=new String(in.readAllBytes(),StandardCharsets.UTF_8);}
  JSONArray all=new JSONArray(content);assertEquals(100,all.length());
  for(int i=0;i<all.length();i++){
   JSONObject fixture=all.getJSONObject(i);String actual=engine.call("nativeReconstruct",fixture.getJSONObject("row").toString());
   assertTrue("Character mismatch at fixture "+i,fixture.getJSONObject("character").similar(new JSONObject(actual)));
   assertEquals("Prompt mismatch at fixture "+i,fixture.getString("prompt"),engine.call("nativePrompt",actual));
  }
 }
 @Test public void catalogHasExpectedCoverage() throws Exception {
  CharacterEngine engine=new CharacterEngine(Files.readString(Path.of("src/main/assets/engine.js")));
  JSONObject catalog=new JSONObject(engine.call("nativeCatalog",""));
  assertEquals(42,catalog.getJSONObject("data").getJSONArray("races").length());
  assertEquals(10,catalog.getJSONArray("rarities").length());assertEquals(47,catalog.getJSONArray("achievements").length());
  int ap=0;for(int i=0;i<47;i++)ap+=catalog.getJSONArray("achievements").getJSONObject(i).getInt("ap");assertEquals(940,ap);
 }
}
