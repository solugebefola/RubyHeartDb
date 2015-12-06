require_relative 'lib/heart_object'

class Cat < HeartObject
  belongs_to :owner, class_name: "Human", foreign_key: :human_id
  has_one_through :home, :owner, :house
end

class Human < HeartObject
  belongs_to :house
  has_many: :cats
end

class House < HeartObject
  has_many :humans
end
