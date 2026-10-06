# I-07 — the single month-bucketing method. Nothing else may call beginning_of_month.
module MonthBucket
  def self.for(date)
    raise ArgumentError, "date is required" if date.nil?
    date.to_date.beginning_of_month
  end

  def self.current
    self.for(Time.zone.today) # never Date.today
  end

  def self.label(date)
    self.for(date).strftime("%Y-%m")
  end
end
