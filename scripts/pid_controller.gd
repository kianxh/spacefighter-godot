extends RefCounted
class_name PidController


var proportionalGain: float
var integralGain: float
var derivativeGain: float

var error_last: float
var value_last: float 
var derivativeMeasurement: DerivativeMeasurement
var derivativeInitialized: bool = false
var integrationStored: float

enum DerivativeMeasurement {
	Velocity,
	ErrorRateOfChange
}

func _init(proportionalGain: float, integralGain: float, derivativeGain: float, derivativeMeasurement) -> void:
	self.proportionalGain = proportionalGain
	self.integralGain = integralGain
	self.derivativeGain = derivativeGain
	self.derivativeMeasurement = derivativeMeasurement

func update(delta: float, current_x:float, target_x: float) -> float:
	# 1. Calculate the difference between the target and current values -> called 'error'
	# 	Note: 	Error is NOT the same as distance! Distance is always non negative 
	#			but error can get negative when the target_x is overshot
	var error: float = target_x - current_x
	
	# The P term (proportional gain) is used for large coarse tuning.
# 	- it must be tuned as FIRST parameter
#	- it has the biggest influence on the returned value
#	- when used in systems with 'momentung' it can cause overshoot (surpassing the target).
#		It will continue moving past the target until the error is big enough
#		to turn back -> short it oscillates (main problem when using PID)
	var P = proportionalGain * error
	
	# The D term acts like a break. The faster P goes the more D grows and counters P as we get 
	#	closer to the target value.
	var error_rate_of_change: float = (error - error_last) / delta
	error_last = error
	
	var value_rate_of_change: float = (current_x - value_last) / delta
	value_last = current_x
		
	
	var deriveMeasure := 0.0
	if derivativeInitialized:
		deriveMeasure = -value_rate_of_change if derivativeMeasurement == DerivativeMeasurement.Velocity else error_rate_of_change
	else:
		derivativeInitialized = true
		
	var D = derivativeGain * deriveMeasure
	
	# I term - builds up over time to support P term
	# Might increase oscillation!
	integrationStored = integrationStored + (error * delta)
	var I = integralGain * integrationStored
	
	print("error: %s | P: %s | D: %s | I: %s" % [error, P, D, I])
	
	return clamp(P + D + I, -1.0, 1.0)
