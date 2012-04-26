require 'spec_helper'

describe Mongoid::Pagination do
  class Group
    include Mongoid::Document

    has_many :persons
  end

  class Person
    include Mongoid::Document
    include Mongoid::Pagination

    belongs_to :group
  end

  describe ".page_size" do
    class Person_50
      include Mongoid::Document
      include Mongoid::Pagination

      self.page_size = 50
    end

    it 'returns configured default page size' do
      Person.page_size.should == 25
      Person_50.page_size.should == 50
    end
  end

  describe ".paginate" do
    let!(:group) { Group.create! }
    let!(:one)   { Person.create!(group: group) }
    let!(:two)   { Person.create!(group: group) }

    context 'without eager loading' do
      subject { Person.paginate(offset: 0, limit: 2) }

      it 'is an paginated array' do
        subject.should be_kind_of(Mongoid::Pagination::Collection)
      end

      context 'for less than a page' do
        it 'returns page size' do
          subject.size.should == 2
          Person.has_more_results?.should == false
          Person.next_offset.should be_nil
          Person.next_offset_at.should == 2
        end
      end
    end

    context 'with eager loading' do
      subject { Person.paginate(offset: 0, limit: 2, eager_load: [ :group ]) }

      it 'is an paginated array' do
        subject.should be_kind_of(Mongoid::Pagination::Collection)
      end

      context 'for less than a page' do
        it 'returns page size' do
          Group.expects(:any_in).once.returns([group])
          subject.size.should == 2
          Person.has_more_results?.should == false
          Person.next_offset.should be_nil
          Person.next_offset_at.should == 2
        end
      end

      context 'for more than a page' do
        let!(:three) { Person.create!(group: group) }
        let!(:four)  { Person.create!(group: group) }

        it 'overfetched by 1' do
          Group.expects(:any_in).once.returns([group])
          subject.size.should == 2
          Person.has_more_results?.should == true
          Person.next_offset.should == 2
          Person.next_offset_at.should == 2
        end
      end
    end
  end

  describe ".paginated_criteria" do
    let!(:one)   { Person.create! }
    let!(:two)   { Person.create! }
    let!(:three) { Person.create! }
    let!(:four)  { Person.create! }

    context "parameter defaults and massaging" do
      describe "when no params are passed in" do
        subject { Person.paginated_criteria }

        it "does not set the skip param by default" do
          subject.options[:skip].should == 0
        end

        it "defaults the limit param to 25" do
          subject.options[:limit].should == 25
        end

        it "returns the criteria unmodified if the limit param is not passed in" do
          criteria = Person.where(:name => 'someone')
          expect {
            criteria.paginated_criteria
          }.not_to change { criteria.options }
        end
      end

      describe "when passed a page param but no limit" do
        subject { Person.paginated_criteria(:page => 1) }

        it "defaults the limit to 25" do
          subject.options[:limit].should == 25
        end

        it "sets the offset to 0" do
          subject.options[:skip].should == 0
        end
      end

      describe "when passed an offset param but no limit" do
        subject { Person.paginated_criteria(:offset => 0) }

        it "defaults the limit to 25" do
          subject.options[:limit].should == 25
        end

        it "sets the offset to 0" do
          subject.options[:skip].should == 0
        end
      end

      describe "when passed a limit param but no page nor offset" do
        subject { Person.paginated_criteria(:limit => 100) }

        it "defaults the offset to 0" do
          subject.options[:skip].should == 0
        end

        it "sets the limit to 100" do
          subject.options[:limit].should == 100
        end
      end

      describe "when passed both page and offset, offset is ignored" do
        subject { Person.paginated_criteria(:page => 2, :offset => 1) }

        it "sets the skip to 25" do
          subject.options[:skip].should == 25
        end
      end

      context 'with page param' do
        it "sets the skip param to 0 if passed 0" do
          Person.paginated_criteria(:page => 0).options[:skip].should == 0
        end

        it "sets the skip param to 0 if passed a string of 0" do
          Person.paginated_criteria(:page => '0').options[:skip].should == 0
        end

        it "sets the skip param to 0 if the passed a string of 1" do
          Person.paginated_criteria(:page => '1').options[:skip].should == 0
        end

        it "limits when passed a string param" do
          Person.paginated_criteria(:limit => '1').to_a.size.should == 1
        end

        it "correctly sets criteria options" do
          Person.paginated_criteria(:limit => 10, :page => 3).options.should == {:limit => 10, :skip => 20}
        end
      end

      context 'with offset param' do
        it "sets the skip param to 0 if passed 0" do
          Person.paginated_criteria(:offset => 0).options[:skip].should == 0
        end

        it "sets the skip param to 0 if passed a string of 0" do
          Person.paginated_criteria(:offset=> '0').options[:skip].should == 0
        end

        it "sets the skip param to 1 if the passed a string of 1" do
          Person.paginated_criteria(:offset => '1').options[:skip].should == 1
        end

        it "sets the skip param with page even if offset is passed as 1" do
          Person.paginated_criteria(:offset => '1', :page => '2').options[:skip].should == 25 
        end

        it "correctly sets criteria options" do
          Person.paginated_criteria(:limit => 10, :offset => 3).options.should == {:limit => 10, :skip => 3}
        end
      end
    end

    context "results" do
      context "with page param" do
        it "paginates correctly on the first page" do
          Person.paginated_criteria(:page => 1, :limit => 2).to_a.should == [one, two]
        end

        it "paginates correctly on the second page" do
          Person.paginated_criteria(:page => 2, :limit => 2).to_a.should == [three, four]
        end
      end

      context "with offset param" do
        it "paginates correctly on the first page" do
          Person.paginated_criteria(:offset => 0, :limit => 2).to_a.should == [one, two]
        end

        it "paginates correctly on the second page" do
          Person.paginated_criteria(:offset => 2, :limit => 2).to_a.should == [three, four]
        end
      end
    end

    it "paginates the result set based on the limit and page params" do
      # Person.
    end
  end

  describe ".per_page" do
    before do
      2.times { Person.create! }
    end

    it "limits the results by the per page param" do
      Person.per_page(1).to_a.size.should == 1
    end

    it "works for string params" do
      Person.per_page('1').to_a.size.should == 1
    end

    it "defaults to 25" do
      Person.per_page.options[:limit].should == 25
    end
  end
end

