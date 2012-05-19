(function(){var a,b=function(a,b){return function(){return a.apply(b,arguments)}};a=typeof global!="undefined"&&global!==null?global:window,a.PivotalApiLib=function(){function a(a){this.account=a,this.delete_comment=b(this.delete_comment,this),this.add_comment=b(this.add_comment,this),this.delete_task=b(this.delete_task,this),this.update_task=b(this.update_task,this),this.add_task=b(this.add_task,this),this.update_story=b(this.update_story,this),this.add_story=b(this.add_story,this),this.get_story=b(this.get_story,this),this.update_account=b(this.update_account,this),this.get_stories_for_project=b(this.get_stories_for_project,this),this.get_projects=b(this.get_projects,this),this.send_pivotal_request=b(this.send_pivotal_request,this)}return a.prototype.baseUrl="https://www.pivotaltracker.com/services/v4",a.prototype.send_pivotal_request=function(a){var b;return b={timeout:8e4,crossDomain:!0,dataType:"xml",headers:{"X-TrackerToken":this.account.token.guid}},a.url!=null&&(b.url=a.url),a.type!=null&&(b.type=a.type),a.data!=null&&(b.data=a.data),a.error!=null&&(b.error=a.error),a.success!=null&&(b.success=a.success),a.complete!=null&&(b.complete=a.complete),a.beforeSend!=null&&(b.beforeSend=a.beforeSend),$.ajax(b)},a.prototype.get_projects=function(a){return a.url=""+this.baseUrl+"/projects",this.send_pivotal_request(a)},a.prototype.get_stories_for_project=function(a){var b;return b=encodeURIComponent("owner:"+this.account.initials),a.requester!=null&&a.requester===!0&&(b=encodeURIComponent("requester:"+this.account.initials)),a.url=""+this.baseUrl+"/projects/"+a.project.id+"/stories?filter="+b,a.success!=null&&(a.success_function=a.success,a.success=function(b,c,d){return a.success_function(b,c,d,a.project)}),this.send_pivotal_request(a)},a.prototype.update_account=function(){return params.url=""+this.baseUrl+"/me",params.success=function(a,b,c){var d,e,f,g;return d=XML2JSON.parse(a,!0),d.person!=null&&(d=d.person),d.email==null?!1:(e=PivotalRocketStorage.get_accounts(),f=function(){var a,b,c;c=[];for(a=0,b=e.length;a<b;a++)g=e[a],g.email!=null&&g.email===d.email?c.push(d):c.push(g);return c}(),PivotalRocketStorage.set_accounts(f))},this.send_pivotal_request(params)},a.prototype.get_story=function(a){return a.url=""+this.baseUrl+"/projects/"+a.project_id+"/stories/"+a.story_id,a.type="GET",this.send_pivotal_request(a)},a.prototype.add_story=function(a){return a.url="https://www.pivotaltracker.com/services/v3/projects/"+a.project_id+"/stories",a.type="POST",this.send_pivotal_request(a)},a.prototype.update_story=function(a){return a.url=""+this.baseUrl+"/projects/"+a.project_id+"/stories/"+a.story_id,a.type="PUT",this.send_pivotal_request(a)},a.prototype.add_task=function(a){return a.url=""+this.baseUrl+"/projects/"+a.project_id+"/stories/"+a.story_id+"/tasks",a.type="POST",this.send_pivotal_request(a)},a.prototype.update_task=function(a){return a.url=""+this.baseUrl+"/projects/"+a.project_id+"/stories/"+a.story_id+"/tasks/"+a.task_id,a.type="PUT",this.send_pivotal_request(a)},a.prototype.delete_task=function(a){return a.url=""+this.baseUrl+"/projects/"+a.project_id+"/stories/"+a.story_id+"/tasks/"+a.task_id,a.type="DELETE",this.send_pivotal_request(a)},a.prototype.add_comment=function(a){return a.url=""+this.baseUrl+"/projects/"+a.project_id+"/stories/"+a.story_id+"/comments",a.type="POST",this.send_pivotal_request(a)},a.prototype.delete_comment=function(a){return a.url=""+this.baseUrl+"/projects/"+a.project_id+"/stories/"+a.story_id+"/comments/"+a.comment_id,a.type="DELETE",this.send_pivotal_request(a)},a}(),a.PivotalAuthLib=function(){function a(a){var b;b={cache:!1,global:!1,dataType:"xml",url:""+this.baseUrl+"/me",success:a.success,error:a.error,beforeSend:a.beforeSend},a.username!=null&&a.password!=null?(b.username=a.username,b.password=a.password):b.headers={"X-TrackerToken":a.token||null},$.ajax(b)}return a.prototype.baseUrl="https://www.pivotaltracker.com/services/v4",a}()}).call(this);
