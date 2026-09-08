package com.genesis.gacha;
import org.mozilla.javascript.*;
/** Pure deterministic reconstruction. No Android UI, browser, network, or ownership writes. */
public final class CharacterEngine {
 private final Scriptable scope;
 public CharacterEngine(String source){Context cx=enter();try{scope=cx.initSafeStandardObjects();cx.evaluateString(scope,source,"genesis-engine",1,null);}finally{Context.exit();}}
 private static Context enter(){Context cx=Context.enter();cx.setOptimizationLevel(-1);cx.setLanguageVersion(Context.VERSION_ES6);cx.setClassShutter(name->false);return cx;}
 public synchronized String call(String name,String json){Context cx=enter();try{Function f=(Function)ScriptableObject.getProperty(scope,name);return Context.toString(f.call(cx,scope,scope,new Object[]{json}));}finally{Context.exit();}}
}
