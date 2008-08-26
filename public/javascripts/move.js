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
$(what+'_botton_'+direction).setStyle({
    backgroundImage: "url('/plugin_assets/cmsplugin/images/move_css/box_arrow_"+direction+".png')"
    });
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
    $(what+'_botton_'+direction).setStyle({
      backgroundImage: "url('/plugin_assets/cmsplugin/images/move_css/box_arrow_"+direction+"_in_move.png')"
    });
    //make move 
    resultedMargin=marginLeftWrapperArea+10;
    $(what+'_list').setStyle({
      marginLeft: resultedMargin+'px'
    });
    } else {
    //not more move, change the image 
    $(what+'_botton_'+direction).setStyle({
      backgroundImage: "url('/plugin_assets/cmsplugin/images/move_css/box_arrow_"+direction+".png')"
    });
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

function changeActiveContent(id_post){
  if (last_active_content) {
    $(last_active_content).removeClassName("active_post");
  } 
  last_active_content="post_"+id_post;
  $(last_active_content).addClassName("active_post");
}

/* DEPRECATED */
function changeDetail(num_content) {
  if(detail_active!='post_detail_'+num_content) {
    Effect.toggle(detail_active,"slide");
    detail_active_div=$(detail_active).remove();
    $('detail_view').insert(detail_active_div);
    //Effect.toggle('post_detail_'+num_content,"slide");
    //detail_active='post_detail_'+num_content;
    detail_to_active_div=$('post_detail_'+num_content).remove();
    $('menu_post_articles_container').update(detail_to_active_div);
    Effect.toggle(detail_active,"slide");
  }
}



