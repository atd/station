// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

// From OpenID server

var CategoryForm = {
  options: { duration: 0.6, activeClass: 'profile-enabled', inactiveClass: 'profile-disabled' },

  set_ids: function(id) {
    this.id = id;
    this.category_id = 'category_content_' + id;
    this.toggle_id = 'toggle_' + id;
  },
  
  check_states: function() {
    this.expanded =  Element.Methods.visible(this.category_id);
    this.active =    $(this.category_id).hasClassName(this.options.activeClass);
  },
  
  expand: function() {
    $(this.category_id).visualEffect('blind_down', this.options);
    $(this.toggle_id).src = '/images/buttons/contract_off.gif';
  },
  
  collapse: function() {
    $(this.category_id).visualEffect('blind_up', this.options);
    $(this.toggle_id).src = '/images/buttons/expand_off.gif';
  },
  
  update: function(id) {
    this.set_ids(id);
    this.check_states();
    
    this.deactivate(this.id);
    $(this.category_id).visualEffect('highlight', { duration: 0.4, queue: 'front' });
  },
  
  deactivate: function(id) {
    this.set_ids(id);
    this.check_states();

    Element.getElementsByClassName(this.category_id,'edit-element').each(function(tr) {
      $(tr).visualEffect('fade');      
    });

    $('edit_icon_'+this.id).visualEffect('fade');

    if($('category_title_'+this.id)) {
      $('category_title_'+this.id).removeClassName(this.options.activeClass);
      $('delete_icon_'+this.id).visualEffect('fade');
    }
    $('category_save_'+this.id).hide();
    $(this.category_id).removeClassName(this.options.activeClass);
  },
  
  activate: function(id) {
    this.set_ids(id);
    this.check_states();
    //alert('activate: '+ this.id);
    Element.getElementsByClassName(this.category_id,'edit-element').each(function(tr) {
      $(tr).visualEffect('appear');
    });
    $('edit_icon_'+this.id).visualEffect('appear');
    // if the category is editable
    if($('category_title_'+this.id)) {
      $('category_title_'+this.id).addClassName(this.options.activeClass);
      $('delete_icon_'+this.id).visualEffect('appear');
    }
    $('category_save_'+this.id).show();
    $(this.category_id).removeClassName(this.options.inactiveClass);
    $(this.category_id).addClassName(this.options.activeClass);
  },
  
  toggle_collapse: function(id) {
    this.set_ids(id);
    this.check_states();
    
    if(this.expanded) {
      this.collapse();
    } else {
      this.expand();
      $(this.category_id).removeClassName('killjoy');
    }
  },
  
  toggle_collapse_and_activation: function(id) {
    this.set_ids(id);
    this.check_states();
    
    // collapsed or expanded?
    if(this.expanded) {
      if(this.active) {
        // if(expanded and active), collapse and deactivate
        this.deactivate(this.id);
      }
      this.collapse();
      $(this.category_id).addClassName('killjoy');
    } else {
      if(!this.active) {
        // if(collapsed and active), expand and activate
        this.activate(this.id);
      }
      this.expand();
    }
  },
  
  toggle_activation: function(id) {
    this.set_ids(id);
    this.check_states();

    if(!this.expanded) {
      this.expand();
    }

    if(this.active) {
      this.deactivate(this.id);
    } else {
      this.activate(this.id);
    }
  },
  
  activate_section: function(id) {
    this.set_ids(id);
    this.check_states();

    if(this.expanded && !this.active && !$(this.category_id).hasClassName('killjoy')) {
      this.activate(this.id);
    }

  },
  
  observe_fields: function(id) {
    this.set_ids(id);
    this.check_states();
    var i = 0;
    Element.getElementsByClassName(this.category_id,'profile-field').each(function(el) {
      Event.observe(el, 'click', function(event) { CategoryForm.toggle_activation(id); } );
    });
  }
};

var DataTable = {
  colorizeRow: function(id) {
    var profile  = $(id);
    var previous = profile.getPreviousSibling('tr');
    if((previous) && (previous.className == 'even')) {
      profile.removeClassName('even');
      profile.addClassName('odd');
    }
  },

  colorizeRows: function(table_id) {
    var i = 0;
    $$('#' + table_id + ' tbody tr').each(function(tr) {
      if(Element.Methods.visible(tr)) {
        tr.className = (i % 2 == 0) ? 'even' : 'odd';
        i++;
      }
    });
  }
};


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
    backgroundImage: "url('../images/move_css/box_arrow_"+direction+".png')"
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
      backgroundImage: "url('../images/move_css/box_arrow_"+direction+"_in_move.png')"
    });
    //make move 
    resultedMargin=marginLeftWrapperArea+10;
    $(what+'_list').setStyle({
      marginLeft: resultedMargin+'px'
    });
    } else {
    //not more move, change the image 
    $(what+'_botton_'+direction).setStyle({
      backgroundImage: "url('../images/move_css/box_arrow_"+direction+".png')"
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



