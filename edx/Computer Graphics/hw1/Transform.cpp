// Transform.cpp: implementation of the Transform class.


#include "Transform.h"

//Please implement the following functions:

// Helper rotation function.  
mat3 Transform::rotate(const float degrees, const vec3& axis) {
  // YOUR CODE FOR HW1 HERE
  float radian=degrees*pi/180;
  vec3 normalized_axis=glm::normalize(axis);

  mat3 tmp;
  for(size_t i=0;i<3;i++) {
    for(size_t j=0;j<3;j++) {
      tmp[i][j]=normalized_axis[i]*normalized_axis[j];
    }
  }

  mat3 A_star(0,-normalized_axis[2],normalized_axis[1],normalized_axis[2],0,-normalized_axis[0],-normalized_axis[1],normalized_axis[0],0);

  // column major
  return glm::transpose(mat3()*glm::cos(radian) + tmp*(1-glm::cos(radian))+A_star*glm::sin(radian));
}

// Transforms the camera left around the "crystal ball" interface
void Transform::left(float degrees, vec3& eye, vec3& up) {
  // YOUR CODE FOR HW1 HERE
  mat3 model=rotate(degrees,vec3(0,1,0));
  eye=model*eye;
  up=model*up;
}

// Transforms the camera up around the "crystal ball" interface
void Transform::up(float degrees, vec3& eye, vec3& up) {
  // YOUR CODE FOR HW1 HERE
  mat3 model=rotate(degrees,vec3(1,0,0));
  eye=model*eye;
  up=model*up;
}

// Your implementation of the glm::lookAt matrix
mat4 Transform::lookAt(vec3 eye, vec3 up) {
  // YOUR CODE FOR HW1 HERE
  vec3 direction=eye;
  vec3 w=glm::normalize(direction);
  vec3 u=glm::normalize(glm::cross(up,w));
  vec3 v=glm::cross(w,u);
  mat4 view;
  // column major
  for(size_t i=0;i<3;i++) {
    view[i][0]=u[i];
    view[i][1]=v[i];
    view[i][2]=w[i];
  }

  mat4 translation;
  for(size_t i=0;i<3;i++) {
    translation[3][i]=-eye[i];
  }
  return view *translation;
}

Transform::Transform()
{

}

Transform::~Transform()
{

}
