function outAngle = interpAngle(lAngle,rAngle,pct)
% computes an interpolated phase angle based on percentage between lAngle and rAngle
% assumes all angles are between -pi and pi.
% interpolates in clockwise (negative) direction from lAngle to rAngle.
% if angle positive and negative representations change, this subfunction should be revisited
  
  %find the difference between the two angles.
  % need to unwrap-5/6*pi
 
  
  if( (lAngle >= 0) && (lAngle >= rAngle))
    angleDiff = lAngle - rAngle;
  elseif( (lAngle >= 0) && (rAngle > lAngle))
    angleDiff = lAngle + pi + (pi - rAngle);
  elseif( (lAngle < 0) && (rAngle <= lAngle))
    angleDiff = lAngle - rAngle;
  elseif( (lAngle < 0) && (rAngle > lAngle))
    angleDiff = pi + lAngle + (pi - rAngle);
  end
  
  outAngle = lAngle - pct*angleDiff;
  
  if(outAngle < -pi)
    outAngle = outAngle + 2*pi;
  end
  
 
 