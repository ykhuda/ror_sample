class Advertisement < ActiveRecord::Base
  include ResourceProxy

  has_many :versioned_advertisements, :dependent => :destroy

  def associated_feature
    workflow_published = Workflow.fetch( "published" )
    @associated_feature ||= Feature.find(:first, 
      :include => [:versioned_page, :advertisement], 
      :conditions => ["versioned_pages.workflow_id = ? AND advertisement_id = ?", workflow_published.id, self.id]
    )
  end
  
  def self.searchable_attributes
    %w( name )
  end

  def self.first_curtain_with_attachment
    if ad = find_published_by_species_name('Curtain').first and ad.attachment and !ad.attachment.filename.blank? 
      return ad
    end
  end

  def self.find_published_by_species_name(name)
    workflow_published = Workflow.fetch( "published" )
    return [] unless species = AdvertisementSpecies.fetch(:all).find { |s| s.name == name }
  
    find(:all, 
      :conditions => [ 'versioned_advertisements.species_id=? AND versioned_advertisements.workflow_id=?', species.id, workflow_published.id ],
      :joins  => :versioned_advertisements,
      :order => 'versioned_advertisements.created_at desc'
    )
  end

  def self.fetch_random( species_id )
    workflow_published = Workflow.fetch( "published" )
    find( :first, 
      :conditions => [ 'versioned_advertisements.species_id=? AND versioned_advertisements.workflow_id=?', species_id, workflow_published.id ], 
      :include => :versioned_advertisements,
      :order => 'RANDOM()'
    )
  end
end
