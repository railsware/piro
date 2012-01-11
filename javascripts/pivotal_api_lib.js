((function(){var a,b=function(a,b){return function(){return a.apply(b,arguments)}};a=typeof global!="undefined"&&global!==null?global:window,a.PivotalApiLib=function(){function a(a){this.account=a,this.formated_date=b(this.formated_date,this),this.get_activities=b(this.get_activities,this),this.update_account=b(this.update_account,this),this.get_stories_for_project_requester=b(this.get_stories_for_project_requester,this),this.get_stories_for_project=b(this.get_stories_for_project,this),this.get_projects=b(this.get_projects,this),$.ajaxSetup({timeout:6e4,crossDomain:!0,dataType:"xml",headers:{"X-TrackerToken":this.account.token.guid}})}return a.prototype.get_projects=function(a){return $.ajax({url:"https://www.pivotaltracker.com/services/v4/projects",success:a.success,error:a.error})},a.prototype.get_stories_for_project=function(a){return $.ajax({url:"http://www.pivotaltracker.com/services/v4/projects/"+a.project.id+"/stories?filter="+encodeURIComponent("owner:"+this.account.initials),success:function(b,c,d){if(a!=null&&a.success!=null)return a.success(b,c,d,a.project)},error:a.error,complete:a.complete})},a.prototype.get_stories_for_project_requester=function(a){return $.ajax({url:"http://www.pivotaltracker.com/services/v4/projects/"+a.project.id+"/stories?filter="+encodeURIComponent("requester:"+this.account.initials),success:function(b,c,d){if(a!=null&&a.success!=null)return a.success(b,c,d,a.project)},error:a.error,complete:a.complete})},a.prototype.update_account=function(){var a=this;return $.ajax({url:"https://www.pivotaltracker.com/services/v4/me",success:function(a,b,c){var d,e,f,g;d=XML2JSON.parse(a,!0),d.person!=null&&(d=d.person);if(d.email!=null)return e=PivotalRocketStorage.get_accounts(),f=function(){var a,b,c;c=[];for(a=0,b=e.length;a<b;a++)g=e[a],g.email!=null?g.email===d.email?c.push(d):c.push(g):c.push(void 0);return c}(),PivotalRocketStorage.set_accounts(f)}})},a.prototype.get_activities=function(a){var b,c=this;return a==null&&(a=new Date),b=this.formated_date(a),console.debug("http://www.pivotaltracker.com/services/v4/activities?limit=100&occurred_since_date="+encodeURIComponent(b)),$.ajax({url:"http://www.pivotaltracker.com/services/v4/activities?limit=100&occurred_since_date="+encodeURIComponent(b),success:function(a,b,c){var d;return d=XML2JSON.parse(a,!0),console.debug(d)}})},a.prototype.formated_date=function(a){return""+a.getFullYear()+"/"+(a.getMonth()+1)+"/"+a.getDate()+" "+a.getHours()+":"+a.getMinutes()+":00"},a}(),a.PivotalAuthLib=function(){function a(a){$.ajax({cache:!1,global:!1,dataType:"xml",headers:{"X-TrackerToken":null},url:"https://www.pivotaltracker.com/services/v4/me",username:a.username,password:a.password,success:a.success,error:a.error,beforeSend:a.beforeSend})}return a}()})).call(this)
