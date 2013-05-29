require "spec_helper"

describe ScrapeHelper do
  before do
    Mongoid.default_session.collections.each { |coll| coll.drop unless /^system/.match(coll.name) }
    @review = FactoryGirl.create(:review)
  end
 
  describe "#enrich_review_with_score" do
    it "finds correct score and adds it to review" do
      @review.score.should == nil
      helper.enrich_review_with_score(@review)
      @review.score.should == 9.3
    end
  end

  describe "#enrich_review_with_artist" do
    it "finds correct artist and adds it to review" do
      @review.artist.should == nil
      helper.enrich_review_with_artist(@review)
      @review.artist.should == "Vampire Weekend"
    end
  end

  describe "#enrich_review_with_album_title" do
    it "finds correct album title and adds it to review" do
      @review.album_title.should == nil
      helper.enrich_review_with_album_title(@review)
      @review.album_title.should == "Modern Vampires of the City"
    end
  end

end
