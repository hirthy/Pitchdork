# Pitchdork

Pitchdork is a tool for scraping information from the record review site [Pitchfork](http://pitchfork.com/).

# Download the reviews
This command must be done before any of the extraction commands. It allows you to download all reviews into your MongoDB database: `rake "scrape:slurp_reviews[MINIMUM_PAGE,MAXIMUM_PAGE]"`. Once complete, you will have several thousand Review objects in your database containing a **url** and an **html** property.

The page numbers refer to the Pitchfork reviews listing pagination -- e.g. this is page 500: [http://pitchfork.com/reviews/albums/500/](http://pitchfork.com/reviews/albums/500/). This command will take a long time to complete. If you'd like to speed it up, you might try shortening the sleep amount between reviews. This can be adjusted in the [ScrapeHelper](https://github.com/kevineder/Pitchdork/blob/master/app/helpers/scrape_helper.rb) module.
Once you've downloaded all the reviews, you can begin extracting information.

# Extract Information
The **html** property of the **Review** model is not modified during the extraction tasks, and the extraction tasks are all idempotent. This means you can adjust the extraction logic for any of the fields and not worry about corrupting your Reviews for good.

## Extract scores
`rake "scrape:find_scores"`

## Extract artists
`rake "scrape:find_artists"`

## Extract album titles
`rake "scrape:find_album_titles`