{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "cdeb0668828214c74f0c30d588a05ff792b9d23c1a6a8d04f213c29c73527515",
  "slang": "glsl430",
  "params": [
    "boost"
  ],
  "textures": [],
  "instanced": [
    {
      "name": "raise",
      "vec4": 0,
      "offset": 0,
      "components": 1
    },
    {
      "name": "tint",
      "vec4": 1,
      "offset": 0,
      "components": 4
    }
  ],
  "instanceVec4": 2,
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 9) in vec4 fa_inst_d0;\nlayout(location = 10) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 7) out vec3 fa_lm;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _100 = (dot(model[0].xyz, _94) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _100, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _100), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(param_6.world_pos, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _2753[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[30];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 10) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 7) in vec3 fa_lm;\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _566 = fa_mesh_fs_params[19].x < 0.0;\n    bool _573;\n    if (!_566)\n    {\n        _573 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _573 = _566;\n    }\n    bool _581;\n    if (!_573)\n    {\n        _581 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _581 = _573;\n    }\n    bool _588;\n    if (!_581)\n    {\n        _588 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _588 = _581;\n    }\n    bool _595;\n    if (!_588)\n    {\n        _595 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _595 = _588;\n    }\n    if (_595)\n    {\n        return vec4(0.0);\n    }\n    vec4 _605 = vec4(world_pos, 1.0);\n    float _612 = dot(fa_mesh_fs_params[16], _605);\n    if (!(_612 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _634 = vec2(dot(fa_mesh_fs_params[14], _605), dot(fa_mesh_fs_params[15], _605)) / vec2(_612);\n    int _638 = int(fa_mesh_fs_params[18].x);\n    int _642 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _642) + clamp(int(floor(((_634.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _642 - 1)) * _638)) + clamp(int(floor(((_634.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _638 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _718 = fa_cluster_texel(param);\n    return ivec2(int(_718.x), int(_718.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _3817 = fa_cluster_lookup(param);\n    fa_cl_slot = _3817.x;\n    fa_cl_local = _3817.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _4036 = fa_linear_to_srgb(param);\n        c = _4036;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _4044 = fa_srgb_to_linear(param_1);\n            c = _4044;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _317;\n    if (i.front_facing)\n    {\n        _317 = i.world_normal;\n    }\n    else\n    {\n        _317 = -i.world_normal;\n    }\n    vec3 _341 = normalize(i.world_tangent.xyz - (_317 * dot(_317, i.world_tangent.xyz)));\n    vec3 _368 = normalize(((_341 * m.x) + ((cross(_317, _341) * i.world_tangent.w) * m.y)) + (_317 * m.z));\n    vec3 _371;\n    if (i.front_facing)\n    {\n        _371 = _368;\n    }\n    else\n    {\n        _371 = -_368;\n    }\n    return _371;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _4075 = fa_tex_fix(param_2, param_3);\n    vec4 _5387 = base_t;\n    _5387.x = _4075.x;\n    _5387.y = _4075.y;\n    _5387.z = _4075.z;\n    base_t = _5387;\n    vec4 _4089 = (_5387 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _5241 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _4121 = fa_tex_fix(param_6, param_7);\n        vec3 _4124 = (_4121 * 2.0) - vec3(1.0);\n        vec2 _4129 = _4124.xy * fa_mesh_fs_params[6].x;\n        vec3 _5395 = _4124;\n        _5395.x = _4129.x;\n        _5395.y = _4129.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _5395;\n        _5241 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _4158 = fa_tex_fix(param_12, param_13);\n    vec4 _5398 = mrt;\n    _5398.x = _4158.x;\n    _5398.y = _4158.y;\n    _5398.z = _4158.z;\n    mrt = _5398;\n    vec4 _4186 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _4186.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _4198 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _4228 = fa_tex_fix(param_20, param_21);\n    float _5246 = fa_mesh_fs_params[20].x;\n    float _5247 = fa_mesh_fs_params[20].y;\n    float _5250 = fa_mesh_fs_params[20].z;\n    float _5249 = fa_mesh_fs_params[21].w;\n    float _5252 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _5246 *= _4198.y;\n            _5247 *= _4198.z;\n            _5249 *= _4186.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _5250 *= mrt.x;\n            _5252 *= mrt.w;\n        }\n    }\n    return Surface(_4089.xyz, _4089.w, _5241, clamp(fa_mesh_fs_params[5].x * _4158.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _4158.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_4198.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _4228), _5246, _5247, fa_mesh_fs_params[21].xyz, _5249, _5250, fa_mesh_fs_params[20].w, _5252, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _799 = rect.zw - rect.xy;\n    vec2 _803 = _799 * atlas;\n    vec2 _807 = ddx * _803;\n    vec2 _811 = ddy * _803;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _799), clamp(0.5 * log2(max(max(dot(_807, _807), dot(_811, _811)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _846 = fa_mesh_fs_params[10].y < 0.5;\n    bool _853;\n    if (!_846)\n    {\n        _853 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _853 = _846;\n    }\n    if (_853)\n    {\n        return;\n    }\n    vec3 _859 = dFdx(world_pos);\n    vec3 _862 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _866 = fa_cluster_texel(param);\n    int _870 = int(_866.w);\n    if (_870 < 1)\n    {\n        return;\n    }\n    int _880 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _880;\n    vec4 _884 = fa_light_texel(param_1);\n    vec2 _887 = _884.yz;\n    int _891 = int(_884.w);\n    int param_2 = _880 + 1;\n    vec4 _896 = fa_light_texel(param_2);\n    float _897 = _896.x;\n    int _903 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _907 = int(_866.z);\n    vec3 _1173;\n    for (int k = 0; k < _870; k++)\n    {\n        int _920 = _907 + k;\n        int param_3 = _891 + (_920 >> 2);\n        int _938 = (_880 + 2) + (int(fa_light_texel(param_3)[_920 & 3]) * 7);\n        int param_4 = _938 + 6;\n        vec4 _943 = fa_light_texel(param_4);\n        if (((int(_943.w + 0.5) >> _903) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _938;\n        vec4 _958 = fa_light_texel(param_5);\n        int param_6 = _938 + 1;\n        vec4 _963 = fa_light_texel(param_6);\n        int param_7 = _938 + 2;\n        vec4 _968 = fa_light_texel(param_7);\n        vec3 _971 = _958.xyz;\n        float _976 = dot(_971, world_pos) + _958.w;\n        vec3 _978 = _963.xyz;\n        float _983 = dot(_978, world_pos) + _963.w;\n        vec3 _985 = _968.xyz;\n        float _990 = dot(_985, world_pos) + _968.w;\n        bool _995 = abs(_976) > 0.5;\n        bool _1003;\n        if (!_995)\n        {\n            _1003 = abs(_983) > 0.5;\n        }\n        else\n        {\n            _1003 = _995;\n        }\n        bool _1011;\n        if (!_1003)\n        {\n            _1011 = abs(_990) > 0.5;\n        }\n        else\n        {\n            _1011 = _1003;\n        }\n        if (_1011)\n        {\n            continue;\n        }\n        float _1026 = clamp(dot(geo_normal, normalize(_985)) * _943.z, 0.0, 1.0);\n        if (_1026 <= 0.0)\n        {\n            continue;\n        }\n        float _1046 = (clamp((0.5 - abs(_990)) * 10.0, 0.0, 1.0) * _1026) * _943.x;\n        vec2 _1054 = vec2(_976 + 0.5, 0.5 - _983);\n        vec2 _1064 = vec2(dot(_971, _859), dot(_978, _859));\n        vec2 _1074 = vec2(dot(_971, _862), dot(_978, _862));\n        int param_8 = _938 + 5;\n        vec4 _1079 = fa_light_texel(param_8);\n        int param_9 = _938 + 3;\n        vec4 _1084 = fa_light_texel(param_9);\n        int param_10 = _938 + 4;\n        vec4 _1089 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1079.xyz;\n        bool _1099 = _1084.z > _1084.x;\n        if (_1099)\n        {\n            vec4 param_11 = _1084;\n            vec2 param_12 = _1054;\n            vec2 param_13 = _887;\n            vec2 param_14 = _1064;\n            vec2 param_15 = _1074;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_897 > 0.5) && (_897 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1125 = fa_dc_to_linear(param_16);\n                vec4 _5297 = tx;\n                _5297.x = _1125.x;\n                _5297.y = _1125.y;\n                _5297.z = _1125.z;\n                tx = _5297;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1046 * tex_a) * _1079.w, 0.0, 1.0)));\n        if (_1089.z > _1089.x)\n        {\n            vec4 param_17 = _1089;\n            vec2 param_18 = _1054;\n            vec2 param_19 = _887;\n            vec2 param_20 = _1064;\n            vec2 param_21 = _1074;\n            vec4 _1169 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_897 > 1.5)\n            {\n                vec3 param_22 = _1169.xyz;\n                vec3 _1179 = fa_dc_to_srgb(param_22);\n                _1173 = _1179;\n            }\n            else\n            {\n                _1173 = _1169.xyz;\n            }\n            vec3 _1189 = (_1173 * 2.0) - vec3(1.0);\n            vec2 _1194 = _1189.xy * _943.y;\n            vec3 _1216 = (normalize(_971) * _1194.x) + (normalize(_978) * _1194.y);\n            vec3 _1219 = normalize(normal);\n            normal = normalize(mix(_1219, normalize((_1219 * max(_1189.z, 0.0500000007450580596923828125)) + (_1216 - (_1219 * dot(_1219, _1216)))), vec3(clamp(_1046 * (_1099 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _2679 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _2686 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _2689 = int(_2679);\n    int _2692 = int(_2686);\n    float _2702 = _2686 - float(_2692);\n    int _2757 = (_2689 * 9) + _2692;\n    int _2777 = ((_2689 + 1) * 9) + _2692;\n    return mix(mix(_2753[_2757], _2753[_2757 + 1], _2702), mix(_2753[_2777], _2753[_2777 + 1], _2702), _2679 - float(_2689));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _5164 = false;\n    float _5165 = 1.0;\n    float _5166 = 1.0;\n    float _5167 = 1.0;\n    float _5168 = 0.0;\n    float _5169 = 0.0;\n    float _5170 = 0.0;\n    float _5171 = 0.0;\n    float _5173 = 1.0;\n    bool _5174 = false;\n    vec3 _5175 = vec3(0.0);\n    float _5176 = 1.0;\n    float _5177 = 1.0;\n    float _5178 = 1.0;\n    float _5179 = 0.0;\n    float _5180 = 0.0;\n    vec3 _5181 = vec3(1.0, 0.0, 0.0);\n    vec3 _5182 = vec3(0.0, 0.0, 1.0);\n    float _5183 = 1.0;\n    float _5184 = 1.0;\n    float _2830 = clamp(s.specular, 0.0, 1.0);\n    float _2834 = clamp(s.ior, 1.0, 3.0);\n    bool _2839 = (_2830 != 1.0) || (_2834 != 1.5);\n    bool _2849;\n    if (!_2839)\n    {\n        _2849 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _2849 = _2839;\n    }\n    if (_2849)\n    {\n        float _2857 = (_2834 - 1.0) / (_2834 + 1.0);\n        f0 = mix(min(vec3(_2857 * _2857) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _2830, s.albedo, vec3(metallic));\n        _5165 = mix(_2830, 1.0, metallic);\n        _5164 = true;\n    }\n    float _2885 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_2885 > 0.0)\n    {\n        float _2893 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _5168 = _2885;\n        _5169 = _2893;\n        float _2900 = _2893 * _2893;\n        _5170 = _2900;\n        _5171 = _2900 * _2900;\n        float _2912 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _5173 = _2912;\n        _5166 = 1.0 - (_2885 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _2912, 0.0, 1.0), 5.0))));\n        _5164 = true;\n    }\n    vec3 _2931 = max(s.sheen_color, vec3(0.0));\n    float _2940 = max(_2931.x, max(_2931.y, _2931.z));\n    if (_2940 > 0.0)\n    {\n        float _2948 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _5174 = true;\n        _5175 = _2931;\n        _5176 = _2948;\n        _5177 = _2948 * _2948;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2948;\n        float _2965 = fa_sheen_albedo(param, param_1);\n        _5179 = _2965;\n        _5178 = 1.0 - min(_2940 * _2965, 1.0);\n        _5164 = true;\n    }\n    _5167 = _5166 * _5178;\n    float _2984 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_2984 != 0.0)\n    {\n        vec3 _2999 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _2999;\n        if (dot(_2999, _2999) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _3012 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_3012.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _3012.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _3012.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _3016 = t;\n        vec3 _3017 = normalize(_3016);\n        t = _3017;\n        vec3 _3042 = normalize((_3017 * cos(s.anisotropy_rotation)) + ((cross(n, _3017) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _5181 = _3042;\n        _5182 = cross(n, _3042);\n        float _3052 = roughness * roughness;\n        float _3058 = mix(_3052, 1.0, _2984 * _2984);\n        bool _3060 = _2984 > 0.0;\n        _5183 = _3060 ? _3058 : _3052;\n        _5184 = _3060 ? _3052 : _3058;\n        _5180 = _2984;\n        _5164 = true;\n    }\n    return FaLayers(_5164, _5165, _5166, _5167, _5168, _5169, _5170, _5171, i.world_normal, _5173, _5174, _5175, _5176, _5177, _5178, _5179, _5180, _5181, _5182, _5183, _5184);\n}\n\nvec3 fa_sky_sh_coef(int k)\n{\n    vec3 v = textureLod(fa_env_tex_fa_env_smp, vec3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), 5.0).xyz;\n    if (fa_mesh_fs_params[11].w > 1.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _2436 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _2436;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _435 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _441 = fa_light_texel(param_1);\n    float _444 = _441.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _450 = _444 < 0.5;\n    vec3 l;\n    if (_450)\n    {\n        l = normalize(_435.xyz);\n    }\n    else\n    {\n        vec3 _462 = _435.xyz - world_pos;\n        float _464 = length(_462);\n        dist = _464;\n        l = _462 / vec3(max(_464, 9.9999997473787516355514526367188e-05));\n        float _479 = _464 / max(_435.w, 0.001000000047497451305389404296875);\n        float _485 = clamp(1.0 - (_479 * _479), 0.0, 1.0);\n        atten = _485 * _485;\n        if (_444 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _499 = fa_light_texel(param_2);\n            float _509 = _499.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _515 = fa_light_texel(param_3);\n            float _516 = _515.x;\n            float cos_inner = _516;\n            if (_516 > 1.5)\n            {\n                cos_inner = mix(_509, 1.0, 0.25);\n            }\n            atten *= smoothstep(_509, cos_inner, dot(-l, normalize(_499.xyz)));\n        }\n    }\n    int _547;\n    if (_450)\n    {\n        _547 = 0;\n    }\n    else\n    {\n        _547 = (_444 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _441.xyz * atten, atten, 1.0, dist, _547);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1291;\n    if (i == 0)\n    {\n        _1291 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _1307;\n        if (i == 1)\n        {\n            _1307 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _1315;\n            if (i == 2)\n            {\n                _1315 = fa_shadows[24].z;\n            }\n            else\n            {\n                _1315 = fa_shadows[24].w;\n            }\n            _1307 = _1315;\n        }\n        _1291 = _1307;\n    }\n    return _1291;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _1348 = fa_shadow_depth(param, param_1);\n    float _1352;\n    if (conv.x < 0.5)\n    {\n        _1352 = _1348;\n    }\n    else\n    {\n        _1352 = (conv.y * conv.z) / (conv.z - (_1348 * (conv.z - conv.y)));\n    }\n    return _1352;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1279 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_1279), sin(_1279)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _1398 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1412 = clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1398;\n            vec2 _1431 = fa_shadow_vogel(param_3, param_4, param_5) * _1412;\n            vec2 param_6 = uv + (_1431 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _1443 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_1443 < (zr - (length(_1431) * plane)))\n            {\n                sum += _1443;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1487 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1487; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1487;\n        float param_11 = _1398;\n        vec2 _1506 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_1506 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_1506) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_1487);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _1548 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _1553 = clamp(dot(n, l), 0.0, 1.0);\n    float _1559 = sqrt(1.0 - (_1553 * _1553));\n    float _1566 = min(_1559 / max(_1553, 0.20000000298023223876953125), 4.0);\n    float _1571;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1571 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1571 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1596 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1571 * _1559)), 1.0);\n    float _1603 = _1596.x;\n    bool _1606 = _1603 < fa_shadows[ci * 1 + 16].x;\n    bool _1615;\n    if (!_1606)\n    {\n        _1615 = _1603 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1615 = _1606;\n    }\n    bool _1624;\n    if (!_1615)\n    {\n        _1624 = _1596.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1624 = _1615;\n    }\n    bool _1633;\n    if (!_1624)\n    {\n        _1633 = _1596.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1633 = _1624;\n    }\n    bool _1640;\n    if (!_1633)\n    {\n        _1640 = _1596.z > 1.0;\n    }\n    else\n    {\n        _1640 = _1633;\n    }\n    if (_1640)\n    {\n        return -1.0;\n    }\n    float _1649;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1649 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1649 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _1596.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _1596.z - ((_1649 * (1.0 + (0.5 * _1566))) / _1548);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _1548;\n    float param_5 = _1548 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_1566, 3.0)) * 0.5) / _1548;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2076 = int(fa_shadows[25].x + 0.5);\n    if (_2076 < 1)\n    {\n        return 1.0;\n    }\n    float _2091 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2076 - 1;\n    if (_2091 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2103 = _2076 > 1;\n    bool _2110;\n    if (_2103)\n    {\n        _2110 = _2091 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2110 = _2103;\n    }\n    if (_2110)\n    {\n        ci = 1;\n    }\n    bool _2114 = _2076 > 2;\n    bool _2121;\n    if (_2114)\n    {\n        _2121 = _2091 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2121 = _2114;\n    }\n    if (_2121)\n    {\n        ci = 2;\n    }\n    bool _2125 = _2076 > 3;\n    bool _2132;\n    if (_2125)\n    {\n        _2132 = _2091 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2132 = _2125;\n    }\n    if (_2132)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2076)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2158 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2158;\n        if (_2158 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2183;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2183 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2183 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2202 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2183, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2213 = clamp((_2091 - (fa_shadow_split_at(param_7) - _2202)) / _2202, 0.0, 1.0);\n        if (_2213 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2076)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2234 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2234;\n                if (_2234 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2213);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _1707 = fa_mesh_fs_params[5].z < 0.5;\n    bool _1715;\n    if (!_1707)\n    {\n        _1715 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _1715 = _1707;\n    }\n    if (_1715)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _1728 = fa_light_texel(param);\n    float _1729 = _1728.x;\n    if (_1729 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1738 = int(_1729 + 0.5);\n    int param_1 = _1738;\n    vec4 _1742 = fa_light_texel(param_1);\n    int param_2 = _1738 + 1;\n    vec4 _1747 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _1750 = _1742.y;\n    if (_1750 > 0.0)\n    {\n        float _1767 = 1.0 - smoothstep(0.75 * _1750, _1750, length(world - fa_shadows[27].xyz));\n        fade = _1767;\n        if (_1767 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1742.x > 1.5)\n    {\n        int param_3 = li * 4;\n        vec3 _1786 = world - fa_light_texel(param_3).xyz;\n        vec3 _1789 = abs(_1786);\n        float _1791 = _1789.x;\n        float _1793 = _1789.y;\n        bool _1794 = _1791 >= _1793;\n        bool _1802;\n        if (_1794)\n        {\n            _1802 = _1791 >= _1789.z;\n        }\n        else\n        {\n            _1802 = _1794;\n        }\n        int _1803;\n        if (_1802)\n        {\n            _1803 = (_1786.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1816;\n            if (_1793 >= _1789.z)\n            {\n                _1816 = (_1786.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1816 = (_1786.z > 0.0) ? 4 : 5;\n            }\n            _1803 = _1816;\n        }\n        face = _1803;\n    }\n    int _1835 = (_1738 + 2) + (face * 6);\n    int param_4 = _1835;\n    int param_5 = _1835 + 1;\n    int param_6 = _1835 + 3;\n    vec4 _1849 = fa_light_texel(param_6);\n    int param_7 = _1835 + 4;\n    vec4 _1854 = fa_light_texel(param_7);\n    int param_8 = _1835 + 5;\n    vec4 _1859 = fa_light_texel(param_8);\n    float _1871 = _1859.x * max(dot(_1849, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1876 = clamp(dot(n, l), 0.0, 1.0);\n    float _1899 = clamp(dot(n, _1849.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1922 = min(sqrt(1.0 - (_1899 * _1899)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1849, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1925 = _1747.y;\n    float _1927;\n    if (_1925 > 0.0)\n    {\n        _1927 = _1925;\n    }\n    else\n    {\n        _1927 = 1.5 * _1871;\n    }\n    vec4 _1947 = vec4(world + (n * (_1927 * sqrt(1.0 - (_1876 * _1876)))), 1.0);\n    float _1951 = dot(_1849, _1947);\n    float _1954 = _1859.y;\n    if (_1951 < _1954)\n    {\n        return 1.0;\n    }\n    vec2 _1969 = vec2(dot(fa_light_texel(param_4), _1947), dot(fa_light_texel(param_5), _1947)) / vec2(_1951);\n    float _1971 = _1969.x;\n    bool _1974 = _1971 < _1854.x;\n    bool _1983;\n    if (!_1974)\n    {\n        _1983 = _1971 > _1854.z;\n    }\n    else\n    {\n        _1983 = _1974;\n    }\n    bool _1992;\n    if (!_1983)\n    {\n        _1992 = _1969.y < _1854.y;\n    }\n    else\n    {\n        _1992 = _1983;\n    }\n    bool _2001;\n    if (!_1992)\n    {\n        _2001 = _1969.y > _1854.w;\n    }\n    else\n    {\n        _2001 = _1992;\n    }\n    if (_2001)\n    {\n        return 1.0;\n    }\n    float _2007 = _1747.x;\n    float _2009;\n    if (_2007 > 0.0)\n    {\n        _2009 = _2007;\n    }\n    else\n    {\n        _2009 = 1.5 * _1871;\n    }\n    vec2 param_10 = _1969;\n    vec4 param_11 = _1854;\n    float param_12 = _1951 - (_2009 * (1.0 + (0.5 * _1922)));\n    float param_13 = _1871;\n    float param_14 = 1.0;\n    float param_15 = _1859.z * 0.25;\n    float param_16 = (_1871 * min(_1922, 3.0)) * 0.5;\n    vec3 param_17 = vec3(1.0, _1954, _1859.z);\n    int param_18 = int(_1742.z + 0.5);\n    float param_19 = _1742.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _3559 = fa_mesh_fs_params[24].x < 0.5;\n    bool _3566;\n    if (!_3559)\n    {\n        _3566 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _3566 = _3559;\n    }\n    if (_3566)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _3579 = fa_light_texel(param);\n    float _3580 = _3579.y;\n    float len = _3580;\n    if (_3580 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3592 = length(world - fa_mesh_fs_params[0].xyz);\n    float _3602 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _3592);\n    if (_3602 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3608 = len;\n    float _3611 = min(_3608, 0.89999997615814208984375 * dist);\n    len = _3611;\n    float _3616 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3592);\n    float _3621 = _3616 + (0.5 * _3611);\n    vec3 _3627 = world + (gn * _3616);\n    float _3629 = fa_shadow_noise();\n    float occ = 0.0;\n    float _3693;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3644 = (float(k) + _3629) * 0.083333335816860198974609375;\n        vec3 _3652 = _3627 + (l * (_3644 * len));\n        vec4 _3658 = vec4(_3652, 1.0);\n        float _3664 = dot(fa_mesh_fs_params[28], _3658);\n        if (_3664 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _3684 = vec2(dot(fa_mesh_fs_params[26], _3658), dot(fa_mesh_fs_params[27], _3658)) / vec2(_3664);\n        float _3688 = _3684.x * 0.5;\n        float _3689 = _3688 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _3693 = (_3684.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _3693 = 0.5 - (_3684.y * 0.5);\n        }\n        bool _3709 = _3689 < 0.0;\n        bool _3716;\n        if (!_3709)\n        {\n            _3716 = _3689 >= 1.0;\n        }\n        else\n        {\n            _3716 = _3709;\n        }\n        bool _3723;\n        if (!_3716)\n        {\n            _3723 = _3693 < 0.0;\n        }\n        else\n        {\n            _3723 = _3716;\n        }\n        bool _3730;\n        if (!_3723)\n        {\n            _3730 = _3693 >= 1.0;\n        }\n        else\n        {\n            _3730 = _3723;\n        }\n        if (_3730)\n        {\n            break;\n        }\n        vec4 _3749 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_3689, _3693) * fa_mesh_fs_params[24].zw), 0);\n        if (_3749.w < 0.5)\n        {\n            continue;\n        }\n        float _3768 = (dot(fa_mesh_fs_params[29].xyz, _3652) + fa_mesh_fs_params[29].w) - _3749.x;\n        if ((_3768 > _3616) && (_3768 < _3621))\n        {\n            occ = max(occ, (1.0 - (_3644 * _3644)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_3689, 0.5 - _3688), min(_3693, 1.0 - _3693))));\n        }\n    }\n    return 1.0 - (occ * _3602);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _3844 = fa_lm.z > 0.5;\n    bool _3850;\n    if (_3844)\n    {\n        int param = li;\n        _3850 = fa_light_baked(param);\n    }\n    else\n    {\n        _3850 = _3844;\n    }\n    if (_3850)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    LightSample _3872 = fa_light_sample(param_2, param_3);\n    vec3 _5226 = _3872.direction;\n    vec3 _5221 = _3872.color;\n    float _5228 = _3872.attenuation;\n    float _5223 = _3872.shadow;\n    float _5230 = _3872._distance;\n    int _5231 = _3872.type;\n    bool _3875 = _5231 == 0;\n    if (_3875 && (li == 0))\n    {\n        vec3 param_4 = gn;\n        vec3 param_5 = _5226;\n        float _3886 = fa_shadow_factor(param_4, param_5);\n        _5223 = _3886;\n        _5221 *= _3886;\n    }\n    else\n    {\n        bool _3897 = _5231 != 0;\n        bool _3903;\n        if (_3897)\n        {\n            _3903 = _5228 > 0.0;\n        }\n        else\n        {\n            _3903 = _3897;\n        }\n        if (_3903)\n        {\n            int param_6 = li;\n            vec3 param_7 = world_pos;\n            vec3 param_8 = gn;\n            vec3 param_9 = _5226;\n            float _3915 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _5223 = _3915;\n            _5221 *= _3915;\n        }\n    }\n    bool _3925 = fa_mesh_fs_params[24].x > 0.5;\n    bool _3931;\n    if (_3925)\n    {\n        _3931 = _5228 > 0.0;\n    }\n    else\n    {\n        _3931 = _3925;\n    }\n    if (_3931)\n    {\n        float _3938;\n        if (_3875)\n        {\n            _3938 = 1000000000.0;\n        }\n        else\n        {\n            _3938 = _5230;\n        }\n        int param_10 = li;\n        vec3 param_11 = world_pos;\n        vec3 param_12 = gn;\n        vec3 param_13 = _5226;\n        float param_14 = _3938;\n        float _3956 = fa_contact_shadow(param_10, param_11, param_12, param_13, param_14);\n        _5223 *= _3956;\n        _5221 *= _3956;\n    }\n    return LightSample(_5226, _5221, _5228, _5223, _5230, _5231);\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _3210 = tdh / at;\n    float _3214 = bdh / ab;\n    float _3226 = ((_3210 * _3210) + (_3214 * _3214)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _3226) * _3226);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _3307 = 1.0 / alpha;\n    return ((2.0 + _3307) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _3307)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _3339 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _3418 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _3418) * _3418);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _3339);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _3339));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _3491 = max(dot(L.nc, l), 0.0);\n        float _3497 = max(dot(L.nc, h), 0.0);\n        float _3506 = ((_3497 * _3497) * (L.coat_a2 - 1.0)) + 1.0;\n        result += vec3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _3506) * _3506)) * (0.5 / max(mix((2.0 * _3491) * L.coat_ndv, _3491 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _3491)) * _3491);\n    }\n    return result;\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _2611 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _2614 = _2611.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_2614 * _2614, exp2((-9.27999973297119140625) * ndv)) * _2614) + _2611.y)) + _2611.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _2465 = rough * rough;\n    float _2495 = 0.60000002384185791015625 * _2465;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _2465)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _2495, 0.0500000007450580596923828125 + _2495, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_2465 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _3093;\n        if (L.aniso >= 0.0)\n        {\n            _3093 = L.b;\n        }\n        else\n        {\n            _3093 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_3093, v), _3093), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3126 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _3126.x) + (vec3(L.f90) * _3126.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _3181 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _3181.x) + _3181.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _2653 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _2653.x) + vec3(_2653.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _2258 = int(fa_shadows[25].x + 0.5);\n    float _2268 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint_1 = vec3(0.3499999940395355224609375);\n    bool _2273 = _2258 > 0;\n    bool _2282;\n    if (_2273)\n    {\n        int param = _2258 - 1;\n        _2282 = _2268 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2282 = _2273;\n    }\n    if (_2282)\n    {\n        tint_1 = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2289 = _2258 > 1;\n        bool _2296;\n        if (_2289)\n        {\n            _2296 = _2268 > fa_shadows[24].x;\n        }\n        else\n        {\n            _2296 = _2289;\n        }\n        if (_2296)\n        {\n            tint_1 = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2302 = _2258 > 2;\n        bool _2309;\n        if (_2302)\n        {\n            _2309 = _2268 > fa_shadows[24].y;\n        }\n        else\n        {\n            _2309 = _2302;\n        }\n        if (_2309)\n        {\n            tint_1 = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2315 = _2258 > 3;\n        bool _2322;\n        if (_2315)\n        {\n            _2322 = _2268 > fa_shadows[24].z;\n        }\n        else\n        {\n            _2322 = _2315;\n        }\n        if (_2322)\n        {\n            tint_1 = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint_1, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _4943 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4943 = -_4943;\n    }\n    vec3 _4368 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _4943, fa_world_tangent, fa_uv, fa_vertex_color, _4368, gl_FrontFacing);\n    Surface _4376 = fa_standard_surface(param_1);\n    vec3 _4974 = _4376.albedo;\n    float _4975 = _4376.alpha;\n    vec3 _4976 = _4376.normal;\n    float _4977 = _4376.metallic;\n    float _4978 = _4376.roughness;\n    float _4979 = _4376.occlusion;\n    vec3 _4980 = _4376.emission;\n    float _4981 = _4376.clearcoat;\n    float _4982 = _4376.clearcoat_roughness;\n    vec3 _4983 = _4376.sheen_color;\n    float _4984 = _4376.sheen_roughness;\n    float _4985 = _4376.anisotropy;\n    float _4986 = _4376.anisotropy_rotation;\n    float _4987 = _4376.specular;\n    float _4988 = _4376.ior;\n    vec3 _4989 = _4376.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _4943, fa_world_tangent, fa_uv, fa_vertex_color, _4368, gl_FrontFacing);\n    Surface param_3 = _4376;\n    surface(param_2, param_3);\n    _4974 = param_3.albedo;\n    _4975 = param_3.alpha;\n    _4976 = param_3.normal;\n    _4977 = param_3.metallic;\n    _4978 = param_3.roughness;\n    _4979 = param_3.occlusion;\n    _4980 = param_3.emission;\n    _4981 = param_3.clearcoat;\n    _4982 = param_3.clearcoat_roughness;\n    _4983 = param_3.sheen_color;\n    _4984 = param_3.sheen_roughness;\n    _4985 = param_3.anisotropy;\n    _4986 = param_3.anisotropy_rotation;\n    _4987 = param_3.specular;\n    _4988 = param_3.ior;\n    _4989 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _4943;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4974 = param_6;\n    _4976 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _4974;\n    }\n    else\n    {\n        vec3 _4415 = normalize(_4976);\n        float _4422 = clamp(_4977, 0.0, 1.0);\n        float _4426 = clamp(_4978, 0.0500000007450580596923828125, 1.0);\n        float _4430 = _4426 * _4426;\n        float _4434 = _4430 * _4430;\n        float _4439 = max(dot(_4415, _4368), 9.9999997473787516355514526367188e-05);\n        vec3 _4445 = _4974 * (1.0 - _4422);\n        vec3 _4452 = mix(vec3(0.039999999105930328369140625), _4974, vec3(_4422));\n        vec3 f0 = _4452;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _4943, fa_world_tangent, fa_uv, fa_vertex_color, _4368, gl_FrontFacing);\n        Surface param_9 = Surface(_4974, _4975, _4976, _4977, _4978, _4979, _4980, _4981, _4982, _4983, _4984, _4985, _4986, _4987, _4988, _4989);\n        vec3 param_10 = _4415;\n        vec3 param_11 = _4368;\n        float param_12 = _4422;\n        float param_13 = _4426;\n        vec3 param_14 = _4452;\n        FaLayers _4468 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _4415;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _4445) * _4979;\n        if (_4468.on)\n        {\n            lit *= _4468.base_scale;\n        }\n        int _4490 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4490; ln++)\n        {\n            int param_16 = ln;\n            int _4503 = fa_cl_light(param_16);\n            bool _4506 = fa_lm.z > 0.5;\n            bool _4512;\n            if (_4506)\n            {\n                int param_17 = _4503;\n                _4512 = fa_light_baked(param_17);\n            }\n            else\n            {\n                _4512 = _4506;\n            }\n            if (_4512)\n            {\n                continue;\n            }\n            int param_18 = _4503;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _4943;\n            LightSample _4524 = fa_light_shadowed(param_18, param_19, param_20);\n            vec3 _5148 = _4524.direction;\n            float _4532 = max(dot(_4415, _5148), 0.0);\n            float _4538 = _4524.attenuation * _4524.shadow;\n            vec3 _4543 = normalize(_5148 + _4368);\n            float _4548 = max(dot(_4415, _4543), 0.0);\n            float _4553 = max(dot(_4368, _4543), 0.0);\n            if (_4468.on)\n            {\n                FaLayers param_21 = _4468;\n                vec3 param_22 = _4445;\n                vec3 param_23 = f0;\n                vec3 param_24 = _4415;\n                vec3 param_25 = _4368;\n                vec3 param_26 = _5148;\n                vec3 param_27 = _4543;\n                float param_28 = _4532;\n                float param_29 = _4439;\n                float param_30 = _4548;\n                float param_31 = _4553;\n                float param_32 = _4430;\n                float param_33 = _4434;\n                int param_34 = _4503;\n                lit += (fa_layers_light(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30, param_31, param_32, param_33) * (fa_light_rgb(param_34) * _4538));\n            }\n            else\n            {\n                float _4601 = ((_4548 * _4548) * (_4434 - 1.0)) + 1.0;\n                int param_35 = _4503;\n                lit += (((_4445 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _4553, 5.0))) * (((_4434 / ((3.1415927410125732421875 * _4601) * _4601)) * (0.5 / max(mix((2.0 * _4532) * _4439, _4532 + _4439, _4430), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4532))) * fa_light_rgb(param_35)) * (_4532 * _4538));\n            }\n        }\n        if (_4468.on)\n        {\n            FaLayers param_36 = _4468;\n            vec3 param_37 = _4415;\n            vec3 param_38 = _4368;\n            vec3 param_39 = f0;\n            float param_40 = _4426;\n            lit += (fa_layers_ibl(param_36, param_37, param_38, param_39, param_40) * _4979);\n        }\n        else\n        {\n            vec3 param_41 = _4415;\n            vec3 param_42 = _4368;\n            vec3 param_43 = f0;\n            float param_44 = _4426;\n            lit += (fa_sky_reflection(param_41, param_42, param_43, param_44) * _4979);\n        }\n        result = lit;\n    }\n    vec3 _4694 = result;\n    vec3 _4695 = _4694 + _4980;\n    result = _4695;\n    vec3 param_45 = _4695;\n    vec3 param_46 = fa_world_pos;\n    result = fa_shadow_debug(param_45, param_46);\n    bool _4704 = fa_mesh_fs_params[7].w > 0.0;\n    bool _4711;\n    if (!_4704)\n    {\n        _4711 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _4711 = _4704;\n    }\n    if (_4711)\n    {\n        vec3 _4720 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _4726 = dot(_4720, fa_mesh_fs_params[9].xyz);\n        bool _4730 = fa_mesh_fs_params[9].w > 0.5;\n        float _4731;\n        if (_4730)\n        {\n            _4731 = _4726;\n        }\n        else\n        {\n            _4731 = length(_4720);\n        }\n        float _4743 = _4731 - fa_mesh_fs_params[8].x;\n        if (_4743 > 0.0)\n        {\n            float _4752 = fa_mesh_fs_params[7].w * _4743;\n            float tau = _4752 * _4752;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _4768;\n                if (_4730)\n                {\n                    _4768 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _4726);\n                }\n                else\n                {\n                    _4768 = fa_mesh_fs_params[0].y;\n                }\n                float _4789 = mix(_4768, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _4731, 0.0, 1.0));\n                float _4793 = fa_world_pos.y - _4789;\n                float _4798 = _4789 - fa_mesh_fs_params[8].z;\n                float _4803 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _4806 = _4798 <= 0.0;\n                bool _4807 = !_4806;\n                bool _4813;\n                if (_4807)\n                {\n                    _4813 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4813 = _4806;\n                }\n                float _4814;\n                if (_4813)\n                {\n                    _4814 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _4814 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _4798, 80.0));\n                }\n                bool _4841;\n                if (_4807)\n                {\n                    _4841 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4841 = _4806;\n                }\n                float _4842;\n                if (_4841)\n                {\n                    _4842 = fa_mesh_fs_params[8].y * _4798;\n                }\n                else\n                {\n                    _4842 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4798, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _4867 = _4803 <= 0.0;\n                bool _4874;\n                if (!_4867)\n                {\n                    _4874 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4874 = _4867;\n                }\n                float _4875;\n                if (_4874)\n                {\n                    _4875 = fa_mesh_fs_params[8].y * _4803;\n                }\n                else\n                {\n                    _4875 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4803, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _4902;\n                if (abs(_4793) < 0.001000000047497451305389404296875)\n                {\n                    _4902 = _4814;\n                }\n                else\n                {\n                    _4902 = (_4875 - _4842) / _4793;\n                }\n                tau += (_4743 * max(_4902, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _4975);\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main"
        },
        "fragment_func": {
          "entry_point": "main"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_position"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_normal"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_texcoord0"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_tangent"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_color"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d0"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d1"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_153",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 11,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_561",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 30,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1301",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 30,
                "offset": 0,
                "glsl_name": "fa_shadows"
              }
            ]
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_3984",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material"
              }
            ]
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "fa_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 1,
              "stage": "fragment",
              "name": "fa_shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 14,
              "stage": "fragment",
              "name": "fa_env_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 24,
              "stage": "fragment",
              "name": "fa_light_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          },
          {
            "texture": {
              "slot": 26,
              "stage": "fragment",
              "name": "fa_lightmap",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 27,
              "stage": "fragment",
              "name": "fa_decal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 28,
              "stage": "fragment",
              "name": "fa_screen_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_shadow_smp",
            "sampler_type": "nonfiltering"
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_env_smp",
            "sampler_type": "filtering"
          },
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering"
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_light_tex_fa_shadow_smp",
            "view_name": "fa_light_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 24,
            "sampler_slot": 1,
            "glsl_name": "fa_light_tex_fa_shadow_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0,
            "glsl_name": "fa_tex_fa_smp"
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0,
            "glsl_name": "fa_normal_tex_fa_smp"
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0,
            "glsl_name": "fa_mr_tex_fa_smp"
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0,
            "glsl_name": "fa_occlusion_tex_fa_smp"
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0,
            "glsl_name": "fa_emissive_tex_fa_smp"
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "fa_decal_tex_fa_env_smp",
            "view_name": "fa_decal_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 27,
            "sampler_slot": 10,
            "glsl_name": "fa_decal_tex_fa_env_smp"
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10,
            "glsl_name": "fa_lightmap_fa_env_smp"
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_env_tex_fa_env_smp"
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1,
            "glsl_name": "fa_screen_tex_fa_shadow_smp"
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 11) in vec4 fa_inst_d0;\nlayout(location = 12) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 7) out vec3 fa_lm;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _196 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_196 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_196 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_196 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _99) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(param_6.world_pos, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _2753[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[30];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 10) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 7) in vec3 fa_lm;\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _566 = fa_mesh_fs_params[19].x < 0.0;\n    bool _573;\n    if (!_566)\n    {\n        _573 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _573 = _566;\n    }\n    bool _581;\n    if (!_573)\n    {\n        _581 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _581 = _573;\n    }\n    bool _588;\n    if (!_581)\n    {\n        _588 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _588 = _581;\n    }\n    bool _595;\n    if (!_588)\n    {\n        _595 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _595 = _588;\n    }\n    if (_595)\n    {\n        return vec4(0.0);\n    }\n    vec4 _605 = vec4(world_pos, 1.0);\n    float _612 = dot(fa_mesh_fs_params[16], _605);\n    if (!(_612 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _634 = vec2(dot(fa_mesh_fs_params[14], _605), dot(fa_mesh_fs_params[15], _605)) / vec2(_612);\n    int _638 = int(fa_mesh_fs_params[18].x);\n    int _642 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _642) + clamp(int(floor(((_634.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _642 - 1)) * _638)) + clamp(int(floor(((_634.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _638 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _718 = fa_cluster_texel(param);\n    return ivec2(int(_718.x), int(_718.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _3817 = fa_cluster_lookup(param);\n    fa_cl_slot = _3817.x;\n    fa_cl_local = _3817.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _4036 = fa_linear_to_srgb(param);\n        c = _4036;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _4044 = fa_srgb_to_linear(param_1);\n            c = _4044;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _317;\n    if (i.front_facing)\n    {\n        _317 = i.world_normal;\n    }\n    else\n    {\n        _317 = -i.world_normal;\n    }\n    vec3 _341 = normalize(i.world_tangent.xyz - (_317 * dot(_317, i.world_tangent.xyz)));\n    vec3 _368 = normalize(((_341 * m.x) + ((cross(_317, _341) * i.world_tangent.w) * m.y)) + (_317 * m.z));\n    vec3 _371;\n    if (i.front_facing)\n    {\n        _371 = _368;\n    }\n    else\n    {\n        _371 = -_368;\n    }\n    return _371;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _4075 = fa_tex_fix(param_2, param_3);\n    vec4 _5387 = base_t;\n    _5387.x = _4075.x;\n    _5387.y = _4075.y;\n    _5387.z = _4075.z;\n    base_t = _5387;\n    vec4 _4089 = (_5387 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _5241 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _4121 = fa_tex_fix(param_6, param_7);\n        vec3 _4124 = (_4121 * 2.0) - vec3(1.0);\n        vec2 _4129 = _4124.xy * fa_mesh_fs_params[6].x;\n        vec3 _5395 = _4124;\n        _5395.x = _4129.x;\n        _5395.y = _4129.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _5395;\n        _5241 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _4158 = fa_tex_fix(param_12, param_13);\n    vec4 _5398 = mrt;\n    _5398.x = _4158.x;\n    _5398.y = _4158.y;\n    _5398.z = _4158.z;\n    mrt = _5398;\n    vec4 _4186 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _4186.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _4198 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _4228 = fa_tex_fix(param_20, param_21);\n    float _5246 = fa_mesh_fs_params[20].x;\n    float _5247 = fa_mesh_fs_params[20].y;\n    float _5250 = fa_mesh_fs_params[20].z;\n    float _5249 = fa_mesh_fs_params[21].w;\n    float _5252 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _5246 *= _4198.y;\n            _5247 *= _4198.z;\n            _5249 *= _4186.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _5250 *= mrt.x;\n            _5252 *= mrt.w;\n        }\n    }\n    return Surface(_4089.xyz, _4089.w, _5241, clamp(fa_mesh_fs_params[5].x * _4158.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _4158.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_4198.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _4228), _5246, _5247, fa_mesh_fs_params[21].xyz, _5249, _5250, fa_mesh_fs_params[20].w, _5252, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _799 = rect.zw - rect.xy;\n    vec2 _803 = _799 * atlas;\n    vec2 _807 = ddx * _803;\n    vec2 _811 = ddy * _803;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _799), clamp(0.5 * log2(max(max(dot(_807, _807), dot(_811, _811)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _846 = fa_mesh_fs_params[10].y < 0.5;\n    bool _853;\n    if (!_846)\n    {\n        _853 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _853 = _846;\n    }\n    if (_853)\n    {\n        return;\n    }\n    vec3 _859 = dFdx(world_pos);\n    vec3 _862 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _866 = fa_cluster_texel(param);\n    int _870 = int(_866.w);\n    if (_870 < 1)\n    {\n        return;\n    }\n    int _880 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _880;\n    vec4 _884 = fa_light_texel(param_1);\n    vec2 _887 = _884.yz;\n    int _891 = int(_884.w);\n    int param_2 = _880 + 1;\n    vec4 _896 = fa_light_texel(param_2);\n    float _897 = _896.x;\n    int _903 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _907 = int(_866.z);\n    vec3 _1173;\n    for (int k = 0; k < _870; k++)\n    {\n        int _920 = _907 + k;\n        int param_3 = _891 + (_920 >> 2);\n        int _938 = (_880 + 2) + (int(fa_light_texel(param_3)[_920 & 3]) * 7);\n        int param_4 = _938 + 6;\n        vec4 _943 = fa_light_texel(param_4);\n        if (((int(_943.w + 0.5) >> _903) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _938;\n        vec4 _958 = fa_light_texel(param_5);\n        int param_6 = _938 + 1;\n        vec4 _963 = fa_light_texel(param_6);\n        int param_7 = _938 + 2;\n        vec4 _968 = fa_light_texel(param_7);\n        vec3 _971 = _958.xyz;\n        float _976 = dot(_971, world_pos) + _958.w;\n        vec3 _978 = _963.xyz;\n        float _983 = dot(_978, world_pos) + _963.w;\n        vec3 _985 = _968.xyz;\n        float _990 = dot(_985, world_pos) + _968.w;\n        bool _995 = abs(_976) > 0.5;\n        bool _1003;\n        if (!_995)\n        {\n            _1003 = abs(_983) > 0.5;\n        }\n        else\n        {\n            _1003 = _995;\n        }\n        bool _1011;\n        if (!_1003)\n        {\n            _1011 = abs(_990) > 0.5;\n        }\n        else\n        {\n            _1011 = _1003;\n        }\n        if (_1011)\n        {\n            continue;\n        }\n        float _1026 = clamp(dot(geo_normal, normalize(_985)) * _943.z, 0.0, 1.0);\n        if (_1026 <= 0.0)\n        {\n            continue;\n        }\n        float _1046 = (clamp((0.5 - abs(_990)) * 10.0, 0.0, 1.0) * _1026) * _943.x;\n        vec2 _1054 = vec2(_976 + 0.5, 0.5 - _983);\n        vec2 _1064 = vec2(dot(_971, _859), dot(_978, _859));\n        vec2 _1074 = vec2(dot(_971, _862), dot(_978, _862));\n        int param_8 = _938 + 5;\n        vec4 _1079 = fa_light_texel(param_8);\n        int param_9 = _938 + 3;\n        vec4 _1084 = fa_light_texel(param_9);\n        int param_10 = _938 + 4;\n        vec4 _1089 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1079.xyz;\n        bool _1099 = _1084.z > _1084.x;\n        if (_1099)\n        {\n            vec4 param_11 = _1084;\n            vec2 param_12 = _1054;\n            vec2 param_13 = _887;\n            vec2 param_14 = _1064;\n            vec2 param_15 = _1074;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_897 > 0.5) && (_897 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1125 = fa_dc_to_linear(param_16);\n                vec4 _5297 = tx;\n                _5297.x = _1125.x;\n                _5297.y = _1125.y;\n                _5297.z = _1125.z;\n                tx = _5297;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1046 * tex_a) * _1079.w, 0.0, 1.0)));\n        if (_1089.z > _1089.x)\n        {\n            vec4 param_17 = _1089;\n            vec2 param_18 = _1054;\n            vec2 param_19 = _887;\n            vec2 param_20 = _1064;\n            vec2 param_21 = _1074;\n            vec4 _1169 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_897 > 1.5)\n            {\n                vec3 param_22 = _1169.xyz;\n                vec3 _1179 = fa_dc_to_srgb(param_22);\n                _1173 = _1179;\n            }\n            else\n            {\n                _1173 = _1169.xyz;\n            }\n            vec3 _1189 = (_1173 * 2.0) - vec3(1.0);\n            vec2 _1194 = _1189.xy * _943.y;\n            vec3 _1216 = (normalize(_971) * _1194.x) + (normalize(_978) * _1194.y);\n            vec3 _1219 = normalize(normal);\n            normal = normalize(mix(_1219, normalize((_1219 * max(_1189.z, 0.0500000007450580596923828125)) + (_1216 - (_1219 * dot(_1219, _1216)))), vec3(clamp(_1046 * (_1099 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _2679 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _2686 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _2689 = int(_2679);\n    int _2692 = int(_2686);\n    float _2702 = _2686 - float(_2692);\n    int _2757 = (_2689 * 9) + _2692;\n    int _2777 = ((_2689 + 1) * 9) + _2692;\n    return mix(mix(_2753[_2757], _2753[_2757 + 1], _2702), mix(_2753[_2777], _2753[_2777 + 1], _2702), _2679 - float(_2689));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _5164 = false;\n    float _5165 = 1.0;\n    float _5166 = 1.0;\n    float _5167 = 1.0;\n    float _5168 = 0.0;\n    float _5169 = 0.0;\n    float _5170 = 0.0;\n    float _5171 = 0.0;\n    float _5173 = 1.0;\n    bool _5174 = false;\n    vec3 _5175 = vec3(0.0);\n    float _5176 = 1.0;\n    float _5177 = 1.0;\n    float _5178 = 1.0;\n    float _5179 = 0.0;\n    float _5180 = 0.0;\n    vec3 _5181 = vec3(1.0, 0.0, 0.0);\n    vec3 _5182 = vec3(0.0, 0.0, 1.0);\n    float _5183 = 1.0;\n    float _5184 = 1.0;\n    float _2830 = clamp(s.specular, 0.0, 1.0);\n    float _2834 = clamp(s.ior, 1.0, 3.0);\n    bool _2839 = (_2830 != 1.0) || (_2834 != 1.5);\n    bool _2849;\n    if (!_2839)\n    {\n        _2849 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _2849 = _2839;\n    }\n    if (_2849)\n    {\n        float _2857 = (_2834 - 1.0) / (_2834 + 1.0);\n        f0 = mix(min(vec3(_2857 * _2857) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _2830, s.albedo, vec3(metallic));\n        _5165 = mix(_2830, 1.0, metallic);\n        _5164 = true;\n    }\n    float _2885 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_2885 > 0.0)\n    {\n        float _2893 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _5168 = _2885;\n        _5169 = _2893;\n        float _2900 = _2893 * _2893;\n        _5170 = _2900;\n        _5171 = _2900 * _2900;\n        float _2912 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _5173 = _2912;\n        _5166 = 1.0 - (_2885 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _2912, 0.0, 1.0), 5.0))));\n        _5164 = true;\n    }\n    vec3 _2931 = max(s.sheen_color, vec3(0.0));\n    float _2940 = max(_2931.x, max(_2931.y, _2931.z));\n    if (_2940 > 0.0)\n    {\n        float _2948 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _5174 = true;\n        _5175 = _2931;\n        _5176 = _2948;\n        _5177 = _2948 * _2948;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2948;\n        float _2965 = fa_sheen_albedo(param, param_1);\n        _5179 = _2965;\n        _5178 = 1.0 - min(_2940 * _2965, 1.0);\n        _5164 = true;\n    }\n    _5167 = _5166 * _5178;\n    float _2984 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_2984 != 0.0)\n    {\n        vec3 _2999 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _2999;\n        if (dot(_2999, _2999) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _3012 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_3012.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _3012.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _3012.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _3016 = t;\n        vec3 _3017 = normalize(_3016);\n        t = _3017;\n        vec3 _3042 = normalize((_3017 * cos(s.anisotropy_rotation)) + ((cross(n, _3017) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _5181 = _3042;\n        _5182 = cross(n, _3042);\n        float _3052 = roughness * roughness;\n        float _3058 = mix(_3052, 1.0, _2984 * _2984);\n        bool _3060 = _2984 > 0.0;\n        _5183 = _3060 ? _3058 : _3052;\n        _5184 = _3060 ? _3052 : _3058;\n        _5180 = _2984;\n        _5164 = true;\n    }\n    return FaLayers(_5164, _5165, _5166, _5167, _5168, _5169, _5170, _5171, i.world_normal, _5173, _5174, _5175, _5176, _5177, _5178, _5179, _5180, _5181, _5182, _5183, _5184);\n}\n\nvec3 fa_sky_sh_coef(int k)\n{\n    vec3 v = textureLod(fa_env_tex_fa_env_smp, vec3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), 5.0).xyz;\n    if (fa_mesh_fs_params[11].w > 1.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _2436 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _2436;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _435 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _441 = fa_light_texel(param_1);\n    float _444 = _441.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _450 = _444 < 0.5;\n    vec3 l;\n    if (_450)\n    {\n        l = normalize(_435.xyz);\n    }\n    else\n    {\n        vec3 _462 = _435.xyz - world_pos;\n        float _464 = length(_462);\n        dist = _464;\n        l = _462 / vec3(max(_464, 9.9999997473787516355514526367188e-05));\n        float _479 = _464 / max(_435.w, 0.001000000047497451305389404296875);\n        float _485 = clamp(1.0 - (_479 * _479), 0.0, 1.0);\n        atten = _485 * _485;\n        if (_444 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _499 = fa_light_texel(param_2);\n            float _509 = _499.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _515 = fa_light_texel(param_3);\n            float _516 = _515.x;\n            float cos_inner = _516;\n            if (_516 > 1.5)\n            {\n                cos_inner = mix(_509, 1.0, 0.25);\n            }\n            atten *= smoothstep(_509, cos_inner, dot(-l, normalize(_499.xyz)));\n        }\n    }\n    int _547;\n    if (_450)\n    {\n        _547 = 0;\n    }\n    else\n    {\n        _547 = (_444 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _441.xyz * atten, atten, 1.0, dist, _547);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1291;\n    if (i == 0)\n    {\n        _1291 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _1307;\n        if (i == 1)\n        {\n            _1307 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _1315;\n            if (i == 2)\n            {\n                _1315 = fa_shadows[24].z;\n            }\n            else\n            {\n                _1315 = fa_shadows[24].w;\n            }\n            _1307 = _1315;\n        }\n        _1291 = _1307;\n    }\n    return _1291;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _1348 = fa_shadow_depth(param, param_1);\n    float _1352;\n    if (conv.x < 0.5)\n    {\n        _1352 = _1348;\n    }\n    else\n    {\n        _1352 = (conv.y * conv.z) / (conv.z - (_1348 * (conv.z - conv.y)));\n    }\n    return _1352;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1279 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_1279), sin(_1279)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _1398 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1412 = clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1398;\n            vec2 _1431 = fa_shadow_vogel(param_3, param_4, param_5) * _1412;\n            vec2 param_6 = uv + (_1431 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _1443 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_1443 < (zr - (length(_1431) * plane)))\n            {\n                sum += _1443;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1487 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1487; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1487;\n        float param_11 = _1398;\n        vec2 _1506 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_1506 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_1506) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_1487);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _1548 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _1553 = clamp(dot(n, l), 0.0, 1.0);\n    float _1559 = sqrt(1.0 - (_1553 * _1553));\n    float _1566 = min(_1559 / max(_1553, 0.20000000298023223876953125), 4.0);\n    float _1571;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1571 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1571 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1596 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1571 * _1559)), 1.0);\n    float _1603 = _1596.x;\n    bool _1606 = _1603 < fa_shadows[ci * 1 + 16].x;\n    bool _1615;\n    if (!_1606)\n    {\n        _1615 = _1603 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1615 = _1606;\n    }\n    bool _1624;\n    if (!_1615)\n    {\n        _1624 = _1596.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1624 = _1615;\n    }\n    bool _1633;\n    if (!_1624)\n    {\n        _1633 = _1596.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1633 = _1624;\n    }\n    bool _1640;\n    if (!_1633)\n    {\n        _1640 = _1596.z > 1.0;\n    }\n    else\n    {\n        _1640 = _1633;\n    }\n    if (_1640)\n    {\n        return -1.0;\n    }\n    float _1649;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1649 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1649 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _1596.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _1596.z - ((_1649 * (1.0 + (0.5 * _1566))) / _1548);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _1548;\n    float param_5 = _1548 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_1566, 3.0)) * 0.5) / _1548;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2076 = int(fa_shadows[25].x + 0.5);\n    if (_2076 < 1)\n    {\n        return 1.0;\n    }\n    float _2091 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2076 - 1;\n    if (_2091 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2103 = _2076 > 1;\n    bool _2110;\n    if (_2103)\n    {\n        _2110 = _2091 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2110 = _2103;\n    }\n    if (_2110)\n    {\n        ci = 1;\n    }\n    bool _2114 = _2076 > 2;\n    bool _2121;\n    if (_2114)\n    {\n        _2121 = _2091 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2121 = _2114;\n    }\n    if (_2121)\n    {\n        ci = 2;\n    }\n    bool _2125 = _2076 > 3;\n    bool _2132;\n    if (_2125)\n    {\n        _2132 = _2091 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2132 = _2125;\n    }\n    if (_2132)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2076)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2158 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2158;\n        if (_2158 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2183;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2183 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2183 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2202 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2183, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2213 = clamp((_2091 - (fa_shadow_split_at(param_7) - _2202)) / _2202, 0.0, 1.0);\n        if (_2213 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2076)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2234 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2234;\n                if (_2234 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2213);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _1707 = fa_mesh_fs_params[5].z < 0.5;\n    bool _1715;\n    if (!_1707)\n    {\n        _1715 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _1715 = _1707;\n    }\n    if (_1715)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _1728 = fa_light_texel(param);\n    float _1729 = _1728.x;\n    if (_1729 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1738 = int(_1729 + 0.5);\n    int param_1 = _1738;\n    vec4 _1742 = fa_light_texel(param_1);\n    int param_2 = _1738 + 1;\n    vec4 _1747 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _1750 = _1742.y;\n    if (_1750 > 0.0)\n    {\n        float _1767 = 1.0 - smoothstep(0.75 * _1750, _1750, length(world - fa_shadows[27].xyz));\n        fade = _1767;\n        if (_1767 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1742.x > 1.5)\n    {\n        int param_3 = li * 4;\n        vec3 _1786 = world - fa_light_texel(param_3).xyz;\n        vec3 _1789 = abs(_1786);\n        float _1791 = _1789.x;\n        float _1793 = _1789.y;\n        bool _1794 = _1791 >= _1793;\n        bool _1802;\n        if (_1794)\n        {\n            _1802 = _1791 >= _1789.z;\n        }\n        else\n        {\n            _1802 = _1794;\n        }\n        int _1803;\n        if (_1802)\n        {\n            _1803 = (_1786.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1816;\n            if (_1793 >= _1789.z)\n            {\n                _1816 = (_1786.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1816 = (_1786.z > 0.0) ? 4 : 5;\n            }\n            _1803 = _1816;\n        }\n        face = _1803;\n    }\n    int _1835 = (_1738 + 2) + (face * 6);\n    int param_4 = _1835;\n    int param_5 = _1835 + 1;\n    int param_6 = _1835 + 3;\n    vec4 _1849 = fa_light_texel(param_6);\n    int param_7 = _1835 + 4;\n    vec4 _1854 = fa_light_texel(param_7);\n    int param_8 = _1835 + 5;\n    vec4 _1859 = fa_light_texel(param_8);\n    float _1871 = _1859.x * max(dot(_1849, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1876 = clamp(dot(n, l), 0.0, 1.0);\n    float _1899 = clamp(dot(n, _1849.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1922 = min(sqrt(1.0 - (_1899 * _1899)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1849, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1925 = _1747.y;\n    float _1927;\n    if (_1925 > 0.0)\n    {\n        _1927 = _1925;\n    }\n    else\n    {\n        _1927 = 1.5 * _1871;\n    }\n    vec4 _1947 = vec4(world + (n * (_1927 * sqrt(1.0 - (_1876 * _1876)))), 1.0);\n    float _1951 = dot(_1849, _1947);\n    float _1954 = _1859.y;\n    if (_1951 < _1954)\n    {\n        return 1.0;\n    }\n    vec2 _1969 = vec2(dot(fa_light_texel(param_4), _1947), dot(fa_light_texel(param_5), _1947)) / vec2(_1951);\n    float _1971 = _1969.x;\n    bool _1974 = _1971 < _1854.x;\n    bool _1983;\n    if (!_1974)\n    {\n        _1983 = _1971 > _1854.z;\n    }\n    else\n    {\n        _1983 = _1974;\n    }\n    bool _1992;\n    if (!_1983)\n    {\n        _1992 = _1969.y < _1854.y;\n    }\n    else\n    {\n        _1992 = _1983;\n    }\n    bool _2001;\n    if (!_1992)\n    {\n        _2001 = _1969.y > _1854.w;\n    }\n    else\n    {\n        _2001 = _1992;\n    }\n    if (_2001)\n    {\n        return 1.0;\n    }\n    float _2007 = _1747.x;\n    float _2009;\n    if (_2007 > 0.0)\n    {\n        _2009 = _2007;\n    }\n    else\n    {\n        _2009 = 1.5 * _1871;\n    }\n    vec2 param_10 = _1969;\n    vec4 param_11 = _1854;\n    float param_12 = _1951 - (_2009 * (1.0 + (0.5 * _1922)));\n    float param_13 = _1871;\n    float param_14 = 1.0;\n    float param_15 = _1859.z * 0.25;\n    float param_16 = (_1871 * min(_1922, 3.0)) * 0.5;\n    vec3 param_17 = vec3(1.0, _1954, _1859.z);\n    int param_18 = int(_1742.z + 0.5);\n    float param_19 = _1742.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _3559 = fa_mesh_fs_params[24].x < 0.5;\n    bool _3566;\n    if (!_3559)\n    {\n        _3566 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _3566 = _3559;\n    }\n    if (_3566)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _3579 = fa_light_texel(param);\n    float _3580 = _3579.y;\n    float len = _3580;\n    if (_3580 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3592 = length(world - fa_mesh_fs_params[0].xyz);\n    float _3602 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _3592);\n    if (_3602 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3608 = len;\n    float _3611 = min(_3608, 0.89999997615814208984375 * dist);\n    len = _3611;\n    float _3616 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3592);\n    float _3621 = _3616 + (0.5 * _3611);\n    vec3 _3627 = world + (gn * _3616);\n    float _3629 = fa_shadow_noise();\n    float occ = 0.0;\n    float _3693;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3644 = (float(k) + _3629) * 0.083333335816860198974609375;\n        vec3 _3652 = _3627 + (l * (_3644 * len));\n        vec4 _3658 = vec4(_3652, 1.0);\n        float _3664 = dot(fa_mesh_fs_params[28], _3658);\n        if (_3664 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _3684 = vec2(dot(fa_mesh_fs_params[26], _3658), dot(fa_mesh_fs_params[27], _3658)) / vec2(_3664);\n        float _3688 = _3684.x * 0.5;\n        float _3689 = _3688 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _3693 = (_3684.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _3693 = 0.5 - (_3684.y * 0.5);\n        }\n        bool _3709 = _3689 < 0.0;\n        bool _3716;\n        if (!_3709)\n        {\n            _3716 = _3689 >= 1.0;\n        }\n        else\n        {\n            _3716 = _3709;\n        }\n        bool _3723;\n        if (!_3716)\n        {\n            _3723 = _3693 < 0.0;\n        }\n        else\n        {\n            _3723 = _3716;\n        }\n        bool _3730;\n        if (!_3723)\n        {\n            _3730 = _3693 >= 1.0;\n        }\n        else\n        {\n            _3730 = _3723;\n        }\n        if (_3730)\n        {\n            break;\n        }\n        vec4 _3749 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_3689, _3693) * fa_mesh_fs_params[24].zw), 0);\n        if (_3749.w < 0.5)\n        {\n            continue;\n        }\n        float _3768 = (dot(fa_mesh_fs_params[29].xyz, _3652) + fa_mesh_fs_params[29].w) - _3749.x;\n        if ((_3768 > _3616) && (_3768 < _3621))\n        {\n            occ = max(occ, (1.0 - (_3644 * _3644)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_3689, 0.5 - _3688), min(_3693, 1.0 - _3693))));\n        }\n    }\n    return 1.0 - (occ * _3602);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _3844 = fa_lm.z > 0.5;\n    bool _3850;\n    if (_3844)\n    {\n        int param = li;\n        _3850 = fa_light_baked(param);\n    }\n    else\n    {\n        _3850 = _3844;\n    }\n    if (_3850)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    LightSample _3872 = fa_light_sample(param_2, param_3);\n    vec3 _5226 = _3872.direction;\n    vec3 _5221 = _3872.color;\n    float _5228 = _3872.attenuation;\n    float _5223 = _3872.shadow;\n    float _5230 = _3872._distance;\n    int _5231 = _3872.type;\n    bool _3875 = _5231 == 0;\n    if (_3875 && (li == 0))\n    {\n        vec3 param_4 = gn;\n        vec3 param_5 = _5226;\n        float _3886 = fa_shadow_factor(param_4, param_5);\n        _5223 = _3886;\n        _5221 *= _3886;\n    }\n    else\n    {\n        bool _3897 = _5231 != 0;\n        bool _3903;\n        if (_3897)\n        {\n            _3903 = _5228 > 0.0;\n        }\n        else\n        {\n            _3903 = _3897;\n        }\n        if (_3903)\n        {\n            int param_6 = li;\n            vec3 param_7 = world_pos;\n            vec3 param_8 = gn;\n            vec3 param_9 = _5226;\n            float _3915 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _5223 = _3915;\n            _5221 *= _3915;\n        }\n    }\n    bool _3925 = fa_mesh_fs_params[24].x > 0.5;\n    bool _3931;\n    if (_3925)\n    {\n        _3931 = _5228 > 0.0;\n    }\n    else\n    {\n        _3931 = _3925;\n    }\n    if (_3931)\n    {\n        float _3938;\n        if (_3875)\n        {\n            _3938 = 1000000000.0;\n        }\n        else\n        {\n            _3938 = _5230;\n        }\n        int param_10 = li;\n        vec3 param_11 = world_pos;\n        vec3 param_12 = gn;\n        vec3 param_13 = _5226;\n        float param_14 = _3938;\n        float _3956 = fa_contact_shadow(param_10, param_11, param_12, param_13, param_14);\n        _5223 *= _3956;\n        _5221 *= _3956;\n    }\n    return LightSample(_5226, _5221, _5228, _5223, _5230, _5231);\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _3210 = tdh / at;\n    float _3214 = bdh / ab;\n    float _3226 = ((_3210 * _3210) + (_3214 * _3214)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _3226) * _3226);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _3307 = 1.0 / alpha;\n    return ((2.0 + _3307) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _3307)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _3339 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _3418 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _3418) * _3418);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _3339);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _3339));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _3491 = max(dot(L.nc, l), 0.0);\n        float _3497 = max(dot(L.nc, h), 0.0);\n        float _3506 = ((_3497 * _3497) * (L.coat_a2 - 1.0)) + 1.0;\n        result += vec3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _3506) * _3506)) * (0.5 / max(mix((2.0 * _3491) * L.coat_ndv, _3491 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _3491)) * _3491);\n    }\n    return result;\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _2611 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _2614 = _2611.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_2614 * _2614, exp2((-9.27999973297119140625) * ndv)) * _2614) + _2611.y)) + _2611.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _2465 = rough * rough;\n    float _2495 = 0.60000002384185791015625 * _2465;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _2465)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _2495, 0.0500000007450580596923828125 + _2495, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_2465 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _3093;\n        if (L.aniso >= 0.0)\n        {\n            _3093 = L.b;\n        }\n        else\n        {\n            _3093 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_3093, v), _3093), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3126 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _3126.x) + (vec3(L.f90) * _3126.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _3181 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _3181.x) + _3181.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _2653 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _2653.x) + vec3(_2653.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _2258 = int(fa_shadows[25].x + 0.5);\n    float _2268 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint_1 = vec3(0.3499999940395355224609375);\n    bool _2273 = _2258 > 0;\n    bool _2282;\n    if (_2273)\n    {\n        int param = _2258 - 1;\n        _2282 = _2268 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2282 = _2273;\n    }\n    if (_2282)\n    {\n        tint_1 = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2289 = _2258 > 1;\n        bool _2296;\n        if (_2289)\n        {\n            _2296 = _2268 > fa_shadows[24].x;\n        }\n        else\n        {\n            _2296 = _2289;\n        }\n        if (_2296)\n        {\n            tint_1 = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2302 = _2258 > 2;\n        bool _2309;\n        if (_2302)\n        {\n            _2309 = _2268 > fa_shadows[24].y;\n        }\n        else\n        {\n            _2309 = _2302;\n        }\n        if (_2309)\n        {\n            tint_1 = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2315 = _2258 > 3;\n        bool _2322;\n        if (_2315)\n        {\n            _2322 = _2268 > fa_shadows[24].z;\n        }\n        else\n        {\n            _2322 = _2315;\n        }\n        if (_2322)\n        {\n            tint_1 = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint_1, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _4943 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4943 = -_4943;\n    }\n    vec3 _4368 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _4943, fa_world_tangent, fa_uv, fa_vertex_color, _4368, gl_FrontFacing);\n    Surface _4376 = fa_standard_surface(param_1);\n    vec3 _4974 = _4376.albedo;\n    float _4975 = _4376.alpha;\n    vec3 _4976 = _4376.normal;\n    float _4977 = _4376.metallic;\n    float _4978 = _4376.roughness;\n    float _4979 = _4376.occlusion;\n    vec3 _4980 = _4376.emission;\n    float _4981 = _4376.clearcoat;\n    float _4982 = _4376.clearcoat_roughness;\n    vec3 _4983 = _4376.sheen_color;\n    float _4984 = _4376.sheen_roughness;\n    float _4985 = _4376.anisotropy;\n    float _4986 = _4376.anisotropy_rotation;\n    float _4987 = _4376.specular;\n    float _4988 = _4376.ior;\n    vec3 _4989 = _4376.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _4943, fa_world_tangent, fa_uv, fa_vertex_color, _4368, gl_FrontFacing);\n    Surface param_3 = _4376;\n    surface(param_2, param_3);\n    _4974 = param_3.albedo;\n    _4975 = param_3.alpha;\n    _4976 = param_3.normal;\n    _4977 = param_3.metallic;\n    _4978 = param_3.roughness;\n    _4979 = param_3.occlusion;\n    _4980 = param_3.emission;\n    _4981 = param_3.clearcoat;\n    _4982 = param_3.clearcoat_roughness;\n    _4983 = param_3.sheen_color;\n    _4984 = param_3.sheen_roughness;\n    _4985 = param_3.anisotropy;\n    _4986 = param_3.anisotropy_rotation;\n    _4987 = param_3.specular;\n    _4988 = param_3.ior;\n    _4989 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _4943;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4974 = param_6;\n    _4976 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _4974;\n    }\n    else\n    {\n        vec3 _4415 = normalize(_4976);\n        float _4422 = clamp(_4977, 0.0, 1.0);\n        float _4426 = clamp(_4978, 0.0500000007450580596923828125, 1.0);\n        float _4430 = _4426 * _4426;\n        float _4434 = _4430 * _4430;\n        float _4439 = max(dot(_4415, _4368), 9.9999997473787516355514526367188e-05);\n        vec3 _4445 = _4974 * (1.0 - _4422);\n        vec3 _4452 = mix(vec3(0.039999999105930328369140625), _4974, vec3(_4422));\n        vec3 f0 = _4452;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _4943, fa_world_tangent, fa_uv, fa_vertex_color, _4368, gl_FrontFacing);\n        Surface param_9 = Surface(_4974, _4975, _4976, _4977, _4978, _4979, _4980, _4981, _4982, _4983, _4984, _4985, _4986, _4987, _4988, _4989);\n        vec3 param_10 = _4415;\n        vec3 param_11 = _4368;\n        float param_12 = _4422;\n        float param_13 = _4426;\n        vec3 param_14 = _4452;\n        FaLayers _4468 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _4415;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _4445) * _4979;\n        if (_4468.on)\n        {\n            lit *= _4468.base_scale;\n        }\n        int _4490 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4490; ln++)\n        {\n            int param_16 = ln;\n            int _4503 = fa_cl_light(param_16);\n            bool _4506 = fa_lm.z > 0.5;\n            bool _4512;\n            if (_4506)\n            {\n                int param_17 = _4503;\n                _4512 = fa_light_baked(param_17);\n            }\n            else\n            {\n                _4512 = _4506;\n            }\n            if (_4512)\n            {\n                continue;\n            }\n            int param_18 = _4503;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _4943;\n            LightSample _4524 = fa_light_shadowed(param_18, param_19, param_20);\n            vec3 _5148 = _4524.direction;\n            float _4532 = max(dot(_4415, _5148), 0.0);\n            float _4538 = _4524.attenuation * _4524.shadow;\n            vec3 _4543 = normalize(_5148 + _4368);\n            float _4548 = max(dot(_4415, _4543), 0.0);\n            float _4553 = max(dot(_4368, _4543), 0.0);\n            if (_4468.on)\n            {\n                FaLayers param_21 = _4468;\n                vec3 param_22 = _4445;\n                vec3 param_23 = f0;\n                vec3 param_24 = _4415;\n                vec3 param_25 = _4368;\n                vec3 param_26 = _5148;\n                vec3 param_27 = _4543;\n                float param_28 = _4532;\n                float param_29 = _4439;\n                float param_30 = _4548;\n                float param_31 = _4553;\n                float param_32 = _4430;\n                float param_33 = _4434;\n                int param_34 = _4503;\n                lit += (fa_layers_light(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30, param_31, param_32, param_33) * (fa_light_rgb(param_34) * _4538));\n            }\n            else\n            {\n                float _4601 = ((_4548 * _4548) * (_4434 - 1.0)) + 1.0;\n                int param_35 = _4503;\n                lit += (((_4445 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _4553, 5.0))) * (((_4434 / ((3.1415927410125732421875 * _4601) * _4601)) * (0.5 / max(mix((2.0 * _4532) * _4439, _4532 + _4439, _4430), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4532))) * fa_light_rgb(param_35)) * (_4532 * _4538));\n            }\n        }\n        if (_4468.on)\n        {\n            FaLayers param_36 = _4468;\n            vec3 param_37 = _4415;\n            vec3 param_38 = _4368;\n            vec3 param_39 = f0;\n            float param_40 = _4426;\n            lit += (fa_layers_ibl(param_36, param_37, param_38, param_39, param_40) * _4979);\n        }\n        else\n        {\n            vec3 param_41 = _4415;\n            vec3 param_42 = _4368;\n            vec3 param_43 = f0;\n            float param_44 = _4426;\n            lit += (fa_sky_reflection(param_41, param_42, param_43, param_44) * _4979);\n        }\n        result = lit;\n    }\n    vec3 _4694 = result;\n    vec3 _4695 = _4694 + _4980;\n    result = _4695;\n    vec3 param_45 = _4695;\n    vec3 param_46 = fa_world_pos;\n    result = fa_shadow_debug(param_45, param_46);\n    bool _4704 = fa_mesh_fs_params[7].w > 0.0;\n    bool _4711;\n    if (!_4704)\n    {\n        _4711 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _4711 = _4704;\n    }\n    if (_4711)\n    {\n        vec3 _4720 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _4726 = dot(_4720, fa_mesh_fs_params[9].xyz);\n        bool _4730 = fa_mesh_fs_params[9].w > 0.5;\n        float _4731;\n        if (_4730)\n        {\n            _4731 = _4726;\n        }\n        else\n        {\n            _4731 = length(_4720);\n        }\n        float _4743 = _4731 - fa_mesh_fs_params[8].x;\n        if (_4743 > 0.0)\n        {\n            float _4752 = fa_mesh_fs_params[7].w * _4743;\n            float tau = _4752 * _4752;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _4768;\n                if (_4730)\n                {\n                    _4768 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _4726);\n                }\n                else\n                {\n                    _4768 = fa_mesh_fs_params[0].y;\n                }\n                float _4789 = mix(_4768, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _4731, 0.0, 1.0));\n                float _4793 = fa_world_pos.y - _4789;\n                float _4798 = _4789 - fa_mesh_fs_params[8].z;\n                float _4803 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _4806 = _4798 <= 0.0;\n                bool _4807 = !_4806;\n                bool _4813;\n                if (_4807)\n                {\n                    _4813 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4813 = _4806;\n                }\n                float _4814;\n                if (_4813)\n                {\n                    _4814 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _4814 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _4798, 80.0));\n                }\n                bool _4841;\n                if (_4807)\n                {\n                    _4841 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4841 = _4806;\n                }\n                float _4842;\n                if (_4841)\n                {\n                    _4842 = fa_mesh_fs_params[8].y * _4798;\n                }\n                else\n                {\n                    _4842 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4798, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _4867 = _4803 <= 0.0;\n                bool _4874;\n                if (!_4867)\n                {\n                    _4874 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4874 = _4867;\n                }\n                float _4875;\n                if (_4874)\n                {\n                    _4875 = fa_mesh_fs_params[8].y * _4803;\n                }\n                else\n                {\n                    _4875 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4803, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _4902;\n                if (abs(_4793) < 0.001000000047497451305389404296875)\n                {\n                    _4902 = _4814;\n                }\n                else\n                {\n                    _4902 = (_4875 - _4842) / _4793;\n                }\n                tau += (_4743 * max(_4902, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _4975);\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main"
        },
        "fragment_func": {
          "entry_point": "main"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_position"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_normal"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_texcoord0"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_tangent"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_color"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_joints"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_weights"
          },
          {
            "slot": 11,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d0"
          },
          {
            "slot": 12,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d1"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_158",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 11,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_205",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 192,
                "offset": 0,
                "glsl_name": "fa_skin"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_561",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 30,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1301",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 30,
                "offset": 0,
                "glsl_name": "fa_shadows"
              }
            ]
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_3984",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material"
              }
            ]
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "fa_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 1,
              "stage": "fragment",
              "name": "fa_shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 14,
              "stage": "fragment",
              "name": "fa_env_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 24,
              "stage": "fragment",
              "name": "fa_light_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          },
          {
            "texture": {
              "slot": 26,
              "stage": "fragment",
              "name": "fa_lightmap",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 27,
              "stage": "fragment",
              "name": "fa_decal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 28,
              "stage": "fragment",
              "name": "fa_screen_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_shadow_smp",
            "sampler_type": "nonfiltering"
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_env_smp",
            "sampler_type": "filtering"
          },
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering"
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_light_tex_fa_shadow_smp",
            "view_name": "fa_light_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 24,
            "sampler_slot": 1,
            "glsl_name": "fa_light_tex_fa_shadow_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0,
            "glsl_name": "fa_tex_fa_smp"
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0,
            "glsl_name": "fa_normal_tex_fa_smp"
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0,
            "glsl_name": "fa_mr_tex_fa_smp"
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0,
            "glsl_name": "fa_occlusion_tex_fa_smp"
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0,
            "glsl_name": "fa_emissive_tex_fa_smp"
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "fa_decal_tex_fa_env_smp",
            "view_name": "fa_decal_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 27,
            "sampler_slot": 10,
            "glsl_name": "fa_decal_tex_fa_env_smp"
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10,
            "glsl_name": "fa_lightmap_fa_env_smp"
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_env_tex_fa_env_smp"
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1,
            "glsl_name": "fa_screen_tex_fa_shadow_smp"
          }
        ]
      }
    },
    "prepass": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 7) out float fa_pre_depth;\nlayout(location = 8) out vec3 fa_pre_r0;\nlayout(location = 9) out vec3 fa_pre_r1;\nlayout(location = 10) out vec3 fa_pre_r2;\nlayout(location = 9) in vec4 fa_inst_d0;\nlayout(location = 10) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _100 = (dot(model[0].xyz, _94) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _100, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _100), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _190 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _197 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_190 * _197).z;\n    fa_pre_r0 = vec3(_190[0].x, _190[1].x, _190[2].x);\n    fa_pre_r1 = vec3(_190[0].y, _190[1].y, _190[2].y);\n    fa_pre_r2 = vec3(_190[0].z, _190[1].z, _190[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _197;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_material[1];\nuniform vec4 fa_mesh_fs_params[30];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 8) in vec3 fa_pre_r0;\nlayout(location = 9) in vec3 fa_pre_r1;\nlayout(location = 10) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 7) in float fa_pre_depth;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _63;\n    if (i.front_facing)\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    vec3 _87 = normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    vec3 _115 = normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    vec3 _118;\n    if (i.front_facing)\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _264 = fa_tex_fix(param_2, param_3);\n    vec4 _771 = base_t;\n    _771.x = _264.x;\n    _771.y = _264.y;\n    _771.z = _264.z;\n    base_t = _771;\n    vec4 _280 = (_771 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _734 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _313 = fa_tex_fix(param_6, param_7);\n        vec3 _317 = (_313 * 2.0) - vec3(1.0);\n        vec2 _322 = _317.xy * fa_mesh_fs_params[6].x;\n        vec3 _779 = _317;\n        _779.x = _322.x;\n        _779.y = _322.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _779;\n        _734 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _351 = fa_tex_fix(param_12, param_13);\n    vec4 _782 = mrt;\n    _782.x = _351.x;\n    _782.y = _351.y;\n    _782.z = _351.z;\n    mrt = _782;\n    vec4 _381 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _381.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _393 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _423 = fa_tex_fix(param_20, param_21);\n    float _739 = fa_mesh_fs_params[20].x;\n    float _740 = fa_mesh_fs_params[20].y;\n    float _743 = fa_mesh_fs_params[20].z;\n    float _742 = fa_mesh_fs_params[21].w;\n    float _745 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _739 *= _393.y;\n            _740 *= _393.z;\n            _742 *= _381.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _743 *= mrt.x;\n            _745 *= mrt.w;\n        }\n    }\n    return Surface(_280.xyz, _280.w, _734, clamp(fa_mesh_fs_params[5].x * _351.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _351.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_393.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _423), _739, _740, fa_mesh_fs_params[21].xyz, _742, _743, fa_mesh_fs_params[20].w, _745, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _645 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _645 = -_645;\n    }\n    vec3 _556 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _645, fa_world_tangent, fa_uv, fa_vertex_color, _556, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _645, fa_world_tangent, fa_uv, fa_vertex_color, _556, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _571 = normalize(param_2.normal);\n    vec3 _586 = normalize(vec3(dot(fa_pre_r0, _571), dot(fa_pre_r1, _571), dot(fa_pre_r2, _571)));\n    float _598 = _586.z;\n    vec2 e = _586.xy / vec2((abs(_586.x) + abs(_586.y)) + abs(_598));\n    if (_598 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main"
        },
        "fragment_func": {
          "entry_point": "main"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_position"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_normal"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_texcoord0"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_tangent"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_color"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d0"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d1"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_153",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 11,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_142",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_253",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 30,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "fa_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering"
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0,
            "glsl_name": "fa_tex_fa_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0,
            "glsl_name": "fa_normal_tex_fa_smp"
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0,
            "glsl_name": "fa_mr_tex_fa_smp"
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0,
            "glsl_name": "fa_occlusion_tex_fa_smp"
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0,
            "glsl_name": "fa_emissive_tex_fa_smp"
          }
        ]
      }
    },
    "prepass_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 7) out float fa_pre_depth;\nlayout(location = 8) out vec3 fa_pre_r0;\nlayout(location = 9) out vec3 fa_pre_r1;\nlayout(location = 10) out vec3 fa_pre_r2;\nlayout(location = 11) in vec4 fa_inst_d0;\nlayout(location = 12) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _196 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_196 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_196 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_196 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _99) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _303 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _310 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_303 * _310).z;\n    fa_pre_r0 = vec3(_303[0].x, _303[1].x, _303[2].x);\n    fa_pre_r1 = vec3(_303[0].y, _303[1].y, _303[2].y);\n    fa_pre_r2 = vec3(_303[0].z, _303[1].z, _303[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _310;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_material[1];\nuniform vec4 fa_mesh_fs_params[30];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 8) in vec3 fa_pre_r0;\nlayout(location = 9) in vec3 fa_pre_r1;\nlayout(location = 10) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 7) in float fa_pre_depth;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _63;\n    if (i.front_facing)\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    vec3 _87 = normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    vec3 _115 = normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    vec3 _118;\n    if (i.front_facing)\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _264 = fa_tex_fix(param_2, param_3);\n    vec4 _771 = base_t;\n    _771.x = _264.x;\n    _771.y = _264.y;\n    _771.z = _264.z;\n    base_t = _771;\n    vec4 _280 = (_771 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _734 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _313 = fa_tex_fix(param_6, param_7);\n        vec3 _317 = (_313 * 2.0) - vec3(1.0);\n        vec2 _322 = _317.xy * fa_mesh_fs_params[6].x;\n        vec3 _779 = _317;\n        _779.x = _322.x;\n        _779.y = _322.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _779;\n        _734 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _351 = fa_tex_fix(param_12, param_13);\n    vec4 _782 = mrt;\n    _782.x = _351.x;\n    _782.y = _351.y;\n    _782.z = _351.z;\n    mrt = _782;\n    vec4 _381 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _381.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _393 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _423 = fa_tex_fix(param_20, param_21);\n    float _739 = fa_mesh_fs_params[20].x;\n    float _740 = fa_mesh_fs_params[20].y;\n    float _743 = fa_mesh_fs_params[20].z;\n    float _742 = fa_mesh_fs_params[21].w;\n    float _745 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _739 *= _393.y;\n            _740 *= _393.z;\n            _742 *= _381.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _743 *= mrt.x;\n            _745 *= mrt.w;\n        }\n    }\n    return Surface(_280.xyz, _280.w, _734, clamp(fa_mesh_fs_params[5].x * _351.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _351.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_393.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _423), _739, _740, fa_mesh_fs_params[21].xyz, _742, _743, fa_mesh_fs_params[20].w, _745, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _645 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _645 = -_645;\n    }\n    vec3 _556 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _645, fa_world_tangent, fa_uv, fa_vertex_color, _556, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _645, fa_world_tangent, fa_uv, fa_vertex_color, _556, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _571 = normalize(param_2.normal);\n    vec3 _586 = normalize(vec3(dot(fa_pre_r0, _571), dot(fa_pre_r1, _571), dot(fa_pre_r2, _571)));\n    float _598 = _586.z;\n    vec2 e = _586.xy / vec2((abs(_586.x) + abs(_586.y)) + abs(_598));\n    if (_598 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main"
        },
        "fragment_func": {
          "entry_point": "main"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_position"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_normal"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_texcoord0"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_tangent"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_color"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_joints"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_weights"
          },
          {
            "slot": 11,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d0"
          },
          {
            "slot": 12,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d1"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_158",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 11,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_205",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 192,
                "offset": 0,
                "glsl_name": "fa_skin"
              }
            ]
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_142",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_253",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 30,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "fa_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering"
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0,
            "glsl_name": "fa_tex_fa_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0,
            "glsl_name": "fa_normal_tex_fa_smp"
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0,
            "glsl_name": "fa_mr_tex_fa_smp"
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0,
            "glsl_name": "fa_occlusion_tex_fa_smp"
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0,
            "glsl_name": "fa_emissive_tex_fa_smp"
          }
        ]
      }
    },
    "shadow": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 9) in vec4 fa_inst_d0;\nlayout(location = 10) in vec4 fa_inst_d1;\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 5) in vec3 fa_normal;\nlayout(location = 7) in vec4 fa_tangent;\nlayout(location = 6) in vec2 fa_texcoord0;\nlayout(location = 8) in vec4 fa_color;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _85 = cross(model[1].xyz, model[2].xyz);\n    float _91 = (dot(model[0].xyz, _85) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_85 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _91, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _91), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(param_6.world_pos, 1.0);\n}\n\n",
      "fs": "#version 430\n\nlayout(location = 0) out vec4 fa_frag_color;\n\nvoid main()\n{\n    fa_frag_color = vec4(gl_FragCoord.z, 0.0, 0.0, 1.0);\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main"
        },
        "fragment_func": {
          "entry_point": "main"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_position"
          },
          {
            "slot": 1,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 2,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          },
          {
            "slot": 5,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_normal"
          },
          {
            "slot": 6,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_texcoord0"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_tangent"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_color"
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d0"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d1"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_144",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 11,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 11) in vec4 fa_inst_d0;\nlayout(location = 12) in vec4 fa_inst_d1;\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\nlayout(location = 5) in vec4 fa_joints;\nlayout(location = 6) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 7) in vec3 fa_normal;\nlayout(location = 9) in vec4 fa_tangent;\nlayout(location = 8) in vec2 fa_texcoord0;\nlayout(location = 10) in vec4 fa_color;\nfloat raise;\nvec4 tint;\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _187 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_187 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_187 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_187 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _90 = cross(model[1].xyz, model[2].xyz);\n    float _96 = (dot(model[0].xyz, _90) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_90 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _96, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _96), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid main()\n{\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    fa_inst_begin();\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    vertex(param_8);\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(param_8.world_pos, 1.0);\n}\n\n",
      "fs": "#version 430\n\nlayout(location = 0) out vec4 fa_frag_color;\n\nvoid main()\n{\n    fa_frag_color = vec4(gl_FragCoord.z, 0.0, 0.0, 1.0);\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main"
        },
        "fragment_func": {
          "entry_point": "main"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_position"
          },
          {
            "slot": 1,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 2,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_joints"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_weights"
          },
          {
            "slot": 7,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_normal"
          },
          {
            "slot": 8,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_texcoord0"
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_tangent"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_color"
          },
          {
            "slot": 11,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d0"
          },
          {
            "slot": 12,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d1"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_149",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 11,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_196",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 192,
                "offset": 0,
                "glsl_name": "fa_skin"
              }
            ]
          }
        ]
      }
    }
  }
}
