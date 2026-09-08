if(!Math.imul)Math.imul=function(a,b){var ah=(a>>>16)&65535,al=a&65535,bh=(b>>>16)&65535,bl=b&65535;return (al*bl+((ah*bl+al*bh)<<16))|0;};
if(!Object.assign)Object.assign=function(t){for(var i=1;i<arguments.length;i++){var s=arguments[i];if(s)Object.keys(s).forEach(function(k){t[k]=s[k];});}return t;};
if(!Object.values)Object.values=function(o){return Object.keys(o).map(function(k){return o[k];});};
if(!Object.entries)Object.entries=function(o){return Object.keys(o).map(function(k){return [k,o[k]];});};
if(!Array.prototype.includes)Array.prototype.includes=function(v){return this.indexOf(v)>=0;};
if(!Array.prototype.find)Array.prototype.find=function(f){for(var i=0;i<this.length;i++)if(f(this[i],i,this))return this[i];};
if(!String.prototype.includes)String.prototype.includes=function(v){return this.indexOf(v)>=0;};
if(!String.prototype.startsWith)String.prototype.startsWith=function(v){return this.slice(0,v.length)===v;};
if(!String.prototype.padStart)String.prototype.padStart=function(n,p){var s=String(this);p=p||' ';while(s.length<n)s=p+s;return s.slice(s.length-n);};
