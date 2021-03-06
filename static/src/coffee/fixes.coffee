'use strict'

# <img> fixes
fromList(document.querySelectorAll "img").map (e) ->
	# ALT fix - Set titles to alt text (xkcd style)
	e.title = e.alt if e.alt != ""

# Handle hash changes
onhashchange = ->
	return unless location.hash.length > 0
	# Post selected
	if location.hash[1] is 'p'
		o.className = o.className.replace "post-selected", "" for o in document.querySelectorAll ".post-selected"
		doc = document.querySelector location.hash
		doc.className = "post post-selected" if doc?

window.addEventListener "hashchange", onhashchange
onhashchange()

# Make page lists
makePageLists = ->
	pageDivs = document.querySelectorAll ".pages"
	for pageDiv in pageDivs
		# Do Next/Previous only when we don't know the number of pages
		maxstr = pageDiv.dataset.max
		max = parseInt maxstr
		continue if maxstr is 'nomax' or max <= 1

		page = parseInt pageDiv.dataset.current
		baseurl = stripPage location.pathname
		pageHTML = "PAGE &nbsp;"

		# make the pages fit the window width (650px is the max-width)
		width = Math.min getViewport().width, 650
		insPage = (i) ->
			pageHTML += if page == i then "<b>#{i}</b> " else "<a href=\"#{baseurl}/page/#{i}\">#{i}</a> "
		insDots = -> pageHTML += "<span class=\"page-dots\">&middot;&middot;&middot;</span> "

		# m = max number of buttons to output (at least 7)
		# we leave 50px for the "PAGE" text and account 30px per button.
		m = Math.max 7, Math.floor((width - 50) / 30)
		if max <= m
			# output all page buttons
			insPage i for i in [1..max]
		else
			left = page - 1
			right = max - page
			a = Math.floor((m-5)/2)
			lrem = Math.max 0, a - left
			rrem = Math.max 0, a - right
			if left <= a + rrem
				insPage i for i in [1..page]
			else
				insPage 1
				insDots()
				insPage i for i in [page-a-rrem..page]
			if page < max
				if right <= a + lrem
					insPage i for i in [page+1..max]
				else
					insPage i for i in [page+1..page+a+lrem]
					insDots()
					insPage max
		pageDiv.innerHTML = pageHTML

makePageLists()
window.onresize = makePageLists

# Count remaining characters in a post
charsCount = (id) ->
	form = document.getElementById id
	if form?
		text = document.querySelector("##{id} textarea")
		div = document.querySelector("##{id} .chars-count")
		text.onkeyup = ->
			remaining = div.dataset.maxlen - text.value.length
			div.innerHTML = "#{remaining} characters left"
			div.className = "chars-count chars-count-padding"
			text.style.borderColor = if remaining < 0 then "#E33" else ""

charsCount "reply-form"

window.charsCount = charsCount

# Setup toggle buttons in light mode
lightimagebtn = document.querySelectorAll ".toggleImage"
imgsetup = (btn) ->
	url = btn.href
	do (url) ->
		btn.removeAttribute 'href'
		btn.onclick = ->
			btn.outerHTML = "<a href=\"#{url}\"><img src=\"#{url}\" /></a>"
imgsetup imgbtn for imgbtn in lightimagebtn

# Tag search / Fulltext search buttons (in pages which have it)
toggleForm = document.getElementById "tagsearch-form"
if toggleForm?
	toggle = window.createElementEx "a", { className: "button", id: "tagsearchbtn", rel: "search" }
	toggle.appendChild document.createTextNode "Tag search"
	toggleForm.parentElement.replaceChild toggle, toggleForm
	toggle.addEventListener "click", ->
		toggle.parentElement.replaceChild toggleForm, toggle
		toggle = document.getElementById('tagsearch-form')
		toggle.addEventListener "submit", ->
			tagsrc = toggle.elements[0]
			tagsrc.value = escapeHTML tagsrc.value.trim().replace /[\s#]+$/g, ''
			return true
		box = document.getElementById "tagsearch"
		AC.toggleAutocomplete box, "#{window.crOpts.basepath}taglist"
		box.focus()

# Unhide post actions to admins
if window.crOpts.adminMode
	for con in document.querySelectorAll ".postactions"
		con.classList.remove 'unavailable'
		con.classList.add 'inlineBlock'

# Setup onhover event for postIdQuote
fromList(document.querySelectorAll('.postIdQuote')).map (e) ->
	e.addEventListener "mouseover", (ev) ->
		postNum = e.innerHTML[10..]
		refId = if postNum == '0' then 'thread' else "p#{postNum}"
		ref = document.getElementById refId
		if ref?.classList?
			if ref.getBoundingClientRect().top > 0
				# post is fully contained in viewport
				ref.classList.add 'highlighted'
			else
				# post is at least partially hidden
				quoted = document.getElementById "#{refId}_quoted"
				unless quoted?
					quoted = window.createElementEx 'article', { className: "post quoted", id: "#{refId}_quoted" }
					quoted.innerHTML = ref.innerHTML
					document.getElementById('quoted_posts').appendChild quoted
				quoted.style.top = "#{Math.max 0, ev.clientY - ref.clientHeight}px"
				quoted.style.left = "#{ev.clientX + 35}px"
				quoted.style.display = 'block'

	e.onmouseout = ->
		post = document.querySelector '.highlighted'
		if post?
			# post in viewport
			post.classList.remove 'highlighted'
		else
			# post hidden
			postNum = e.innerHTML[10..]
			refId = if postNum == '0' then 'thread_quoted' else "p#{postNum}_quoted"
			post = document.getElementById refId
			post?.style.display = ''

# Unhide siteoptions button
document.getElementById('siteOptions')?.style.display = 'inline'
