var bridge = require("./bridge");
var transformer = require("./transformer");
var refs = require("./refs");

//TODO: move makeTablesNotBlockIfSafeToDoSo, hideAudioTags and reduceWeirdWebkitMargin out into own js object.

bridge.registerListener( "setLanguage", function( payload ){
    var html = document.querySelector( "html" );
    html.lang = payload.lang;
    html.dir = payload.dir;
    html.classList.add( 'content-' + payload.dir );
    html.classList.add( 'ui-' + payload.uidir );
    document.querySelector('base').href = 'https://' + payload.lang + '.wikipedia.org/';
} );

bridge.registerListener( "setScale", function( payload ) {
    var contentSettings = [
        "width=device-width",
        "initial-scale=1.0",
        "user-scalable=yes",
        "minimum-scale=" + payload.min,
        "maximum-scale=" + payload.max
    ];
    var content = contentSettings.join(", ");
    document.getElementById("viewport").setAttribute('content', content);
} );

bridge.registerListener( "append", function( payload ) {
    // Append html without losing existing event handlers
    // From: http://stackoverflow.com/a/595825

    var newcontent = document.createElement('div');
    newcontent.innerHTML = payload.html;

    transformer.transform( "relocateInfobox", newcontent );
    transformer.transform( "hideRedlinks", newcontent );
    transformer.transform( "disableFilePageEdit", newcontent );
    transformer.transform( "hideAudioTags", newcontent );
    transformer.transform( "overflowWideTables", newcontent );
    
    var content = document.getElementById("content");
    // Ensure we've done transforms *before* appending the new content.
    // Otherwise the web view dom will thrash.
    content.appendChild(newcontent);
});

bridge.registerListener( "injectNonLeadSections", function( payload ) {
    // Append html without losing existing event handlers
    // From: http://stackoverflow.com/a/595825

    var newcontent = document.createElement('div');
    newcontent.innerHTML = payload.html;

    //transformer.transform( "relocateInfobox", newcontent );
    transformer.transform( "hideRedlinks", newcontent );
    transformer.transform( "disableFilePageEdit", newcontent );
    transformer.transform( "hideAudioTags", newcontent );
    transformer.transform( "overflowWideTables", newcontent );
    
    var content = document.getElementById("nonLeadSectionsInjectionPoint");
    // Ensure we've done transforms *before* injecting the new content.
    // Otherwise the web view dom will thrash.
    content.parentNode.replaceChild(newcontent, content);
});

bridge.registerListener( "remove", function( payload ) {
    document.getElementById( "content" ).removeChild(document.getElementById(payload.element));
});

bridge.registerListener( "clear", function( payload ) {
    document.getElementById( "content" ).innerHTML = '';
});

bridge.registerListener( "ping", function( payload ) {
    bridge.sendMessage( "pong", payload );
});

bridge.registerListener( "scrollToFragment", function( payload ) {
    var item = document.getElementById( payload.hash );
    var rect = item.getBoundingClientRect();
    window.scroll( 0, rect.top );
});

bridge.registerListener( "setPageProtected", function() {
    document.getElementsByTagName( "html" )[0].classList.add( "page-protected" );
} );

/**
 * Quickie function to walk from the current element up to parents and match CSS-ish selectors.
 * Think of it as a reverse element.querySelector :)
 *
 * Takes only element names, raw classes, and ids right now. Combines all given.
 */
function findParent(element, selector) {
    var matches = selector.match(/^([a-z0-9]*)(?:\.([a-z0-9-]+))?(?:#([a-z0-9-]+))?$/i);
    if (matches) {
        var selectorName = matches[1] || null;
        var selectorClass = matches[2] || null;
        var selectorId = matches[3] || null;
        
        var candidate = element;
        while (candidate) {
            do {
                if (selectorName && candidate.tagName && selectorName.toLowerCase() !== candidate.tagName.toLowerCase()) {
                    break;
                }
                if (selectorClass && !(candidate.classList && candidate.classList.contains(selectorClass))) {
                    break;
                }
                if (selectorId && selectorId !== candidate.id) {
                    break;
                }
                return candidate;
            } while (false);
            candidate = candidate.parentNode;
        }
    } else {
        throw new Error("Unexpected findParent selector format: " + selector);
    }
    return null;
}

document.onclick = function() {
    // Reminder: resist adding any click/tap handling here - they can
    // "fight" with items in the touchEndedWithoutDragging handler.
    // Add click/tap handling to touchEndedWithoutDragging instead.
    event.preventDefault(); // <-- Do not remove!
}

touchDownY = 0.0;
function touchStart(event){
    touchDownY = parseInt(event.changedTouches[0].clientY);
}
document.addEventListener("touchstart", touchStart, "false");

function handleTouchEnded(event){
    var touchobj = event.changedTouches[0];
    touchEndY = parseInt(touchobj.clientY);
    if (((touchDownY - touchEndY) == 0) && (event.changedTouches.length == 1)) {
        // None of our tap events should fire if the user dragged the page at all.
        touchEndedWithoutDragging(event);
    }
}

function touchEndedWithoutDragging(event){
    // Refactored to keep number of findParent calls to a minimum.
    var anchorTarget = findParent(event.target, 'A');
    var anchorTargetFound = anchorTarget && (anchorTarget.tagName === "A") ? true : false;

    // Handle A tag taps.
    if(anchorTargetFound){
        var href = anchorTarget.getAttribute( "href" );
        if (anchorTarget.className === "edit_section_button") {
            bridge.sendMessage( 'editClicked', { sectionId: anchorTarget.getAttribute( "data-id" ) });
        } else if ( refs.isReference( href ) ) {
            // Handle reference links with a popup view instead of scrolling about!
            refs.sendNearbyReferences( anchorTarget );
        } else if ( href[0] === "#" ) {
            // If it is a link to an anchor in the current page, just scroll to it
            document.getElementById( href.substring( 1 ) ).scrollIntoView();
        } else {
            bridge.sendMessage( 'linkClicked', { href: anchorTarget.getAttribute( "href" ) });
        }
    
    // Handle BUTTON tag taps.
    }else{
        var buttonTarget = findParent(event.target, 'BUTTON');
        var buttonTargetFound = buttonTarget && (buttonTarget.tagName === "BUTTON") ? true : false;
        if(buttonTargetFound){
            if (buttonTarget.id === "mw-language-button") {
                bridge.sendMessage( 'langClicked', {} );
            }else if (buttonTarget.id === "mw-last-modified") {
                bridge.sendMessage( 'historyClicked', {} );
            }
        }else{
            // Do NOT prevent default behavior -- this is needed to for instance
            // handle deselection of text.
            bridge.sendMessage( 'nonAnchorTouchEndedWithoutDragging', { id: event.target.getAttribute( "id" ), tagName: event.target.tagName});
        }
    }
}

document.addEventListener("touchend", handleTouchEnded, "false");
