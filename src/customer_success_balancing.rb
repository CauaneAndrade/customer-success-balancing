require 'minitest/autorun'
require 'timeout'

class CustomerSuccessBalancing
  def initialize(customer_success, customers, away_customer_success)
    @customer_success = customer_success
    @customers = customers
    @away_customer_success = away_customer_success
  end

  def self.get_customer_success_id (customer_success, customers)
    """
    Get the Id of the Customer Success with most Customers or 0 if repeated

    :return: Int: the Customer Sucess Id
    """
    hash = {}
    customer_success.each { |c| hash[c[:id]] = 0 }
    customers.group_by { |c| c[:score] }.each {
      |score, items|
      cs = customer_success.select { |cs| cs[:score] >= score }.shift
      if cs && !cs.empty?
        hash[cs[:id]] += items.length
      end
    }

    length = hash.select {|_, v| v == hash.values.max }.length
    is_repeated = length != 1
    return 0 if is_repeated
    return hash.max_by{|k,v| v}[0]
  end

  def self.customer_success_filtered (customer_success_all, away_customer_success)
    """
    Filter available Customer Success.
    Remove the Customer Success that aren`t available.

    :return: The Customer Success array sorted 
    """
    customer_success = customer_success_all.select {
      |cs| !away_customer_success.include? cs[:id]
    }
    return customer_success.sort_by { |hsh| hsh[:score] }
  end

  def execute
    """
    Análise do algoritmo
      Tempo de execução é no pior caso Sub-linear (n log n)

    :return: the ID of the customer success with most customers
    """
    customers_arr = @customers.sort_by { |hsh| hsh[:score] }
    customer_success_arr = self.class.customer_success_filtered @customer_success, @away_customer_success
    
    if !customers_arr.empty?
      customer_success_arr = customer_success_arr.select{|k| k[:score] >= customers_arr[0][:score]}  # somente score maior ou igual ao mínimo score do Customer
    end
    if !customer_success_arr.empty?
      customers_arr = customers_arr.select{|k| k[:score] <= customer_success_arr[-1][:score]}  # somente score menor ou igual ao máximo score do Customer Sucess
    end
    return self.class.get_customer_success_id customer_success_arr, customers_arr
  end
end

class CustomerSuccessBalancingTests < Minitest::Test
  def test_scenario_one
    balancer = CustomerSuccessBalancing.new(
      build_scores([60, 20, 95, 75]),
      build_scores([90, 20, 70, 40, 60, 10]),
      [2, 4]
    )
    assert_equal 1, balancer.execute
  end

  def test_scenario_two
    balancer = CustomerSuccessBalancing.new(
      build_scores([11, 21, 31, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_three
    balancer = CustomerSuccessBalancing.new(
      build_scores(Array(1..999)),
      build_scores(Array.new(10000, 998)),
      [999]
    )
    result = Timeout.timeout(1.0) { balancer.execute }
    assert_equal 998, result
  end

  def test_scenario_four
    balancer = CustomerSuccessBalancing.new(
      build_scores([1, 2, 3, 4, 5, 6]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_five
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 2, 3, 6, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 1, balancer.execute
  end

  def test_scenario_six
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 99, 88, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      [1, 3, 2]
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_seven
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 99, 88, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      [4, 5, 6]
    )
    assert_equal 3, balancer.execute
  end

  private

  def build_scores(scores)
    scores.map.with_index do |score, index|
      { id: index + 1, score: score }
    end
  end
end
