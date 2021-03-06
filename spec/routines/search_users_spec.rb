require 'spec_helper'

describe SearchUsers do
  
  let!(:user_1)          { FactoryGirl.create :user_with_emails, 
                                              first_name: 'John',
                                              last_name: 'Stravinsky',
                                              username: 'jstrav' }
  let!(:user_2)          { FactoryGirl.create :user,
                                              first_name: 'Mary',
                                              last_name: 'Mighty',
                                              full_name: 'Mary Mighty',
                                              username: 'mary' }
  let!(:user_3)          { FactoryGirl.create :user, 
                                              first_name: 'John',
                                              last_name: 'Stead',
                                              username: 'jstead' }

  let!(:user_4)          { FactoryGirl.create :user_with_emails, 
                                              first_name: 'Bob',
                                              last_name: 'JST',
                                              username: 'bigbear' }

  before(:each) do
    MarkContactInfoVerified.call(user_1.contact_infos.email_addresses.first)
    MarkContactInfoVerified.call(user_4.contact_infos.email_addresses.first)
    user_4.contact_infos.email_addresses.first.update_attribute(:value, 'jstoly292929@hotmail.com')
  end

  it "should match based on username" do
    outcome = SearchUsers.call('username:jstra').outputs.users.all
    expect(outcome).to eq [user_1]
  end

  it "should ignore leading wildcards on username searches" do
    outcome = SearchUsers.call('username:%rav').outputs.users.all
    expect(outcome).to eq []
  end

  it "should match based on one first name" do
    outcome = SearchUsers.call('first_name:"John"').outputs.users.all
    expect(outcome).to eq [user_3, user_1]
  end

  it "should match based on one full name" do
    outcome = SearchUsers.call('full_name:"Mary Mighty"').outputs.users.all
    expect(outcome).to eq [user_2]
  end

  it "should match based on an exact email address" do
    email = user_1.contact_infos.email_addresses.first.value
    outcome = SearchUsers.call("email:#{email}").outputs.users.all
    expect(outcome).to eq [user_1]
  end

  it "should not match based on an incomplete email address" do
    email = user_1.contact_infos.email_addresses.first.value.split('@').first
    outcome = SearchUsers.call("email:#{email}").outputs.users.all
    expect(outcome).to eq []
  end

  it "should not return any results if the query is empty" do
    outcome = SearchUsers.call("").outputs.users.all
    expect(outcome).to eq []
  end

  it "should not return any results if there is no usable part of the query" do
    outcome = SearchUsers.call("blah:foo").outputs.users.all
    expect(outcome).to eq []
  end

  it "should match any fields when no prefix given" do
    outcome = SearchUsers.call("jst").outputs.users.all
    expect(outcome).to eq [user_4, user_3, user_1]
  end

  it "should match any fields when no prefix given and intersect when prefix given" do
    outcome = SearchUsers.call("jst username:jst").outputs.users.all
    expect(outcome).to eq [user_3, user_1]
  end

  it "shouldn't allow users to add their own wildcards" do
    outcome = SearchUsers.call("username:'%ar'").outputs.users.all
    expect(outcome).to eq []
  end

  it "should gather space-separated unprefixed search terms" do
    outcome = SearchUsers.call("john mighty").outputs.users.all
    expect(outcome).to eq [user_3, user_1, user_2]
  end

  context "pagination and sorting" do

    let!(:billy_users) {
      (0..45).to_a.collect{|ii|
        FactoryGirl.create :user, 
                           first_name: "Billy#{ii.to_s.rjust(2, '0')}",
                           last_name: "Bob_#{(45-ii).to_s.rjust(2,'0')}",
                           username: "billy_#{ii.to_s.rjust(2, '0')}"
      }
    }

    it "should return the first page of values by default in default order" do
      outcome = SearchUsers.call("username:billy").outputs.users.all
      expect(outcome.length).to eq 20
      expect(outcome[0]).to eq User.where{username.eq "billy_00"}.first
      expect(outcome[19]).to eq User.where{username.eq "billy_19"}.first
    end

    it "should return the 2nd page when requested" do
      outcome = SearchUsers.call("username:billy", page: 1).outputs.users.all
      expect(outcome.length).to eq 20
      expect(outcome[0]).to eq User.where{username.eq "billy_20"}.first
      expect(outcome[19]).to eq User.where{username.eq "billy_39"}.first
    end

    it "should return the incomplete 3rd page when requested" do
      outcome = SearchUsers.call("username:billy", page: 2).outputs.users.all
      expect(outcome.length).to eq 6
      expect(outcome[5]).to eq User.where{username.eq "billy_45"}.first
    end

  end

  context "sorting" do

    let!(:bob_brown) { FactoryGirl.create :user, first_name: "Bob", last_name: "Brown", username: "foo_bb" }
    let!(:bob_jones) { FactoryGirl.create :user, first_name: "Bob", last_name: "Jones", username: "foo_bj" }
    let!(:tim_jones) { FactoryGirl.create :user, first_name: "Tim", last_name: "Jones", username: "foo_tj" }

    it "should allow sort by multiple fields in different directions" do
      outcome = SearchUsers.call("username:foo", order_by: "first_name, last_name DESC").outputs.users.all
      expect(outcome).to eq [bob_jones, bob_brown, tim_jones]

      outcome = SearchUsers.call("username:foo", order_by: "first_name, last_name ASC").outputs.users.all
      expect(outcome).to eq [bob_brown, bob_jones, tim_jones]
    end

  end

end