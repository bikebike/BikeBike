/*!CK:3689363778!*//*1427143565,*/

if (self.CavalryLogger) { CavalryLogger.start_js(["Jmji5"]); }

__d("NavigationMetrics",["Arbiter","BigPipe","NavigationMetrics-upstream","PageEvents"],function(a,b,c,d,e,f,g,h,i,j){b.__markCompiled&&b.__markCompiled();var k={};i.init=function(l){g.subscribe(h.Events.init,function(m,n){var o=n.arbiter;o.subscribe(h.Events.tti,function(p,q){if(q.ajax){var r=k[q.rid];if(r)r.tti=q.ts;}else l.setTTI(q.ts);});o.subscribe(j.AJAXPIPE_SEND,function(p,q){if(q.quickling)k[q.rid]={start:q.ts};});o.subscribe(j.AJAXPIPE_ONLOAD,function(p,q){var r=k[q.rid];if(r){l.setStart(r.start);l.setTTI(r.tti);l.setE2E(q.ts);l.doneNavigation();}});});g.subscribe(j.BIGPIPE_ONLOAD,function(m,n){l.setE2E(n.ts);l.doneNavigation();});};e.exports=i;},null);