# Pitchdork

Pitchdork is a tool for scraping and enriching information from the record review site [Pitchfork](http://pitchfork.com/). Frontend still to come.

## Download the reviews
This command must be done before any of the extraction commands. It allows you to download all reviews into your MongoDB database: `rake "scrape:slurp_reviews[MINIMUM_PAGE,MAXIMUM_PAGE]"`. Once complete, you will have several thousand Review objects in your database containing a **url** and an **html** property.

The page numbers refer to the Pitchfork reviews listing pagination -- e.g. this is page 500: [http://pitchfork.com/reviews/albums/500/](http://pitchfork.com/reviews/albums/500/). This command will take a long time to complete. If you'd like to speed it up, you might try shortening the sleep amount between reviews. This can be adjusted in the [ScrapeHelper](https://github.com/kevineder/Pitchdork/blob/master/app/helpers/scrape_helper.rb) module. Please be considerate of Pitchfork's servers!

Once you've downloaded all the reviews, you can begin extracting information.

## Extract Information
The **html** property of the **Review** model is not modified during the extraction tasks, and the extraction tasks are all idempotent. This means you can adjust the extraction logic for any of the fields and not worry about corrupting your Reviews for good.

### Extract scores
`rake "scrape:find_scores"`

### Extract artists
`rake "scrape:find_artists"`

### Extract reviewer names
`rake "scrape:find_reviewers"`

### Extract album titles
`rake "scrape:find_album_titles"`

### Download album artwork
`rake "scrape:find_album_images"`

Downloads the album artwork from Pitchfork's servers and places it in `/app/assets/images/album_art`. It also sets the image name in the Review object.

## Add Metadata

### Find Spotify metadata
`rake "scrape:find_spotify_metadata"`

Grabs metadata (track uris, album uris, popularity score, et cetera) from Spotify's Web API.
