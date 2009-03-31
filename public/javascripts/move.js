// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

//Function for over the content information

function showContentInfo(evnt,layer) {
nameInfo = layer + "-info";
nameArticle = layer

//get de element by id
var layerInfo = document.getElementById(nameInfo);

//If is the first time that the mouse over pute on, we take the position
	
layerInfo.style.display = "block";


var layerArticle = document.getElementById(nameArticle);
layerArticle.style.zIndex = "0";



}

function hideContentInfo(layer) {
nameInfo = layer + "-info";
nameArticle = layer

	var layerInfo = document.getElementById(nameInfo);
	layerInfo.style.display = "none";


	var layerArticle = document.getElementById(nameArticle);
	layerArticle.style.zIndex = "1";
	
}



var stateMove=0
//Function to change the state of the movement and shoot the differents actions
function setStateMove(state,direction,what) {
//Take the value
stateMove=state;
//make move
makeMove(direction,what);	
}

//Function that read the state of movement, and if it is true, callback other time itself (move function)
function makeMove(direction,what) {
//Comand to callback
moveCommand="makeMove('"+direction+"','"+what+"')";
//if state movement is true
if (stateMove==1) {
//exec move function
makeScroll(direction,what);
//100 ms timeout and callback other time
setTimeout(moveCommand, 50);	
}

//always change the image
if (stateMove==0) {
//$(what+'_botton_'+direction).setStyle({
//    backgroundImage: "url('/plugin_assets/cmsplugin/images/move_css/box_arrow_"+direction+".png')"
//    });
}

}

function makeScroll(direction,what) {
  //How many is the max visible area
  visibleWidthWrapperArea=parseFloat($(what+'_wrapper').getStyle('width'));
  //Where is the margin 
  marginLeftWrapperArea=parseFloat($(what+'_list').getStyle('margin-left'));
  //Total Dimensions  of the list
  totalDimenensionsList=$(what+'_list').getDimensions();
  //split it into variables  
  var listWidth = totalDimenensionsList.width;
  var listHeight = totalDimenensionsList.height;

  //Ok. make the differents movements
  if ((direction=='right') && ((listWidth+marginLeftWrapperArea)>visibleWidthWrapperArea)) {
    resultedMargin=marginLeftWrapperArea-10;
    $(what+'_list').setStyle({
    marginLeft: resultedMargin+'px'
    });
  }

  if (direction=='left') { 
    if ((marginLeftWrapperArea)<5) {
    //the botton can move 
    //change image
    // FIXME not needed change image, just add active class TODO
    //$(what+'_botton_'+direction).setStyle({
    //  backgroundImage: "url('/plugin_assets/cmsplugin/images/move_css/box_arrow_"+direction+"_in_move.png')"
    //});
    //make move 
    resultedMargin=marginLeftWrapperArea+10;
    $(what+'_list').setStyle({
      marginLeft: resultedMargin+'px'
    });
    } else {
    //not more move, change the image 
    //$(what+'_botton_'+direction).setStyle({
    //  backgroundImage: "url('/plugin_assets/cmsplugin/images/move_css/box_arrow_"+direction+".png')"
    //});
    }
  }
}

//Special things maded for special brownser
/*Konqueror
  - Problem with style class box_view_list. Needed to have the inline-block attribute, if not, the script doesn't take the with of this inline style box
*/
function onLoadPage() {
if  (browsername=navigator.appName=='Konqueror') {
  //change the display for this elements FIXME, improve it with a for method
  $('users_list').setStyle({
    display: 'inline-block'
  });
    $('groups_list').setStyle({
    display: 'inline-block'
  });
  
  }
}

var last_login_box;

function loginSelector(which_div) {
  if (!last_login_box) {
    last_login_box = "login_by_user";
  }

  // if wich div are the login options, puts also go button  
  if((which_div=="login_by_user") || (which_div=="login_by_openid")) {
     $('go').setStyle({
      'display': "block"
    })
  } else {
    $('go').setStyle({
      'display': "none"
    })
  }

  $(last_login_box).setStyle({
    'display': "none"
    })
  $(which_div).setStyle({
    'display': "block"
    })
  last_login_box=which_div;
 }

var last_active_content;

function changeActiveContent(id_entry){
  if (last_active_content) {
    $(last_active_content).removeClassName("active_entry");
  } 
  last_active_content="entry_"+id_entry;
  $(last_active_content).addClassName("active_entry");
}


function go_to_content_if_active(id_entry,entry_url) {
  if (last_active_content == ("entry_"+id_entry)) {
    document.location = entry_url;
  }
}


/* Perfomances */
function addNewPerformance(stage_id, stage_name) {
    //FIXME: markup element for fix empty performances non-updating when nothing is sended
    if ($('fix_performance_empty')) {
      $('fix_performance_empty').remove();
    }

    element = $('empty_performance');
    var clone = new Element(element.tagName);
    $A(element.attributes).each(function(attribute) {
     clone[attribute.name] = attribute.value; 
    });

    //take number of permission and increment
    number_permission = parseInt($('performances_length').value);
    $('performances_length').value = number_permission + 1;
    //Data
    clone.update(element.innerHTML);
    //change the input id and name
    clone.childElements().each(function(child) {
      if (child["id"] == "delete_performance") {
        child["id"] = child["id"] + "_" + number_permission;
      } else if (child["id"] == "_agent") {
        child["id"] = "performances_" + number_permission + child["id"];
      } else {
        child["id"] = "performances_" + number_permission + child["id"];
        child["name"] = stage_name + "[_stage_performances][]" + child["name"];
      }
    })
    //Reparse
    clone["id"] = "div_performance_" + number_permission;
    //Insert in html
    $('performances_list_'+stage_id).insert(clone,{'position' : 'bottom'});
  }

  function selectAgentAttributesForPerformances(select_agent_field) {
    agent_data = select_agent_field.value.split('_')
    $(select_agent_field.identify()+'_type').value = agent_data[0]
    $(select_agent_field.identify()+'_id').value = agent_data[1]
  }

var last_role_details;

function showRolesDetails(select_roles_tag,evt) {
  if (last_role_details) {
    $('role_data_'+last_role_details).hide()
  }
  if (select_roles_tag.value != "") {
    $('role_data_'+select_roles_tag.value).show();
    last_role_details = select_roles_tag.value;
  }
}

function hideRolesDetails() {
  if (last_role_details) {
    $('role_data_'+last_role_details).hide()
  }
}

function deletePerformance(delete_link,stage_id, stage_name) {
  //get parent div
  parent_div = 'div' + delete_link.identify().split('delete')[1];
  $(parent_div).remove();
  //if is the last => 
  //FIXME: markup element for fix empty performances non-updating when nothing is sended
  if ($('performances_list_'+stage_id).childElements().length <= 1) {
    var fix_performance_empty = new Element('input', { 'type': 'hidden', 'id': 'fix_performance_empty', 'value': "", 'name': stage_name + "[_stage_performances][]" });
    // add to performaces_list
    $('performances_list_'+stage_id).insert(fix_performance_empty);
  }
}



// END performances functions


/* DEPRECATED */
function changeDetail(num_content) {
  if(detail_active!='entry_detail_'+num_content) {
    Effect.toggle(detail_active,"slide");
    detail_active_div=$(detail_active).remove();
    $('detail_view').insert(detail_active_div);
    //Effect.toggle('entry_detail_'+num_content,"slide");
    //detail_active='entry_detail_'+num_content;
    detail_to_active_div=$('entry_detail_'+num_content).remove();
    $('menu_entry_articles_container').update(detail_to_active_div);
    Effect.toggle(detail_active,"slide");
  }
}



