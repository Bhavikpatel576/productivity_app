$(function() {

	$("form.delete").submit(function(event) {
		event.preventDefault();
		event.stopPropagation();

		var ok = confirm("Are you sure? This cannot be undone!");
		if (ok) {
			//this.submit
			var form = $(this);
			var request = $.ajax({
				url: form.attr("action"), //action is the div tag for the url
				method: form.attr("method") //provides us with the post request?
			});

			request.done(function(data, textStatus, jqXHR){
				form.parent("li").remove()
			}); //excuted when correctly fired

			// request.fail(function()) <-- should add this in production app
		}
	});

});


//comments on code: the preventDefault function prevents the default submission from happening. Stop Propagation 
//prevents the event from 'bubbling up' or being interpreted by another part of the page.
//this.submit : this refers to the form object