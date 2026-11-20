{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "57cbd5df71b0000e548dcd5fbfe873bc15510a64a336f6248792368f21adbf33",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4291[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[50];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 7) in vec3 fa_lm;\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1546 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1553;\n    if (!_1546)\n    {\n        _1553 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1553 = _1546;\n    }\n    bool _1561;\n    if (!_1553)\n    {\n        _1561 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1561 = _1553;\n    }\n    bool _1568;\n    if (!_1561)\n    {\n        _1568 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1568 = _1561;\n    }\n    bool _1575;\n    if (!_1568)\n    {\n        _1575 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1575 = _1568;\n    }\n    if (_1575)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1585 = vec4(world_pos, 1.0);\n    float _1591 = dot(fa_mesh_fs_params[16], _1585);\n    if (!(_1591 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1613 = vec2(dot(fa_mesh_fs_params[14], _1585), dot(fa_mesh_fs_params[15], _1585)) / vec2(_1591);\n    int _1617 = int(fa_mesh_fs_params[18].x);\n    int _1621 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1621) + clamp(int(floor(((_1613.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1621 - 1)) * _1617)) + clamp(int(floor(((_1613.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1617 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1697 = fa_cluster_texel(param);\n    return ivec2(int(_1697.x), int(_1697.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5389 = fa_cluster_lookup(param);\n    fa_cl_slot = _5389.x;\n    fa_cl_local = _5389.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _6553 = fa_linear_to_srgb(param);\n        c = _6553;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _6561 = fa_srgb_to_linear(param_1);\n            c = _6561;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _490;\n    if (i.front_facing)\n    {\n        _490 = i.world_normal;\n    }\n    else\n    {\n        _490 = -i.world_normal;\n    }\n    vec3 _514 = normalize(i.world_tangent.xyz - (_490 * dot(_490, i.world_tangent.xyz)));\n    vec3 _541 = normalize(((_514 * m.x) + ((cross(_490, _514) * i.world_tangent.w) * m.y)) + (_490 * m.z));\n    vec3 _544;\n    if (i.front_facing)\n    {\n        _544 = _541;\n    }\n    else\n    {\n        _544 = -_541;\n    }\n    return _544;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _6592 = fa_tex_fix(param_2, param_3);\n    vec4 _8077 = base_t;\n    _8077.x = _6592.x;\n    _8077.y = _6592.y;\n    _8077.z = _6592.z;\n    base_t = _8077;\n    vec4 _6606 = (_8077 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _7877 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _6638 = fa_tex_fix(param_6, param_7);\n        vec3 _6641 = (_6638 * 2.0) - vec3(1.0);\n        vec2 _6646 = _6641.xy * fa_mesh_fs_params[6].x;\n        vec3 _8085 = _6641;\n        _8085.x = _6646.x;\n        _8085.y = _6646.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _8085;\n        _7877 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _6674 = fa_tex_fix(param_12, param_13);\n    vec4 _8088 = mrt;\n    _8088.x = _6674.x;\n    _8088.y = _6674.y;\n    _8088.z = _6674.z;\n    mrt = _8088;\n    vec4 _6702 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _6702.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _6713 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _6743 = fa_tex_fix(param_20, param_21);\n    float _7882 = fa_mesh_fs_params[20].x;\n    float _7883 = fa_mesh_fs_params[20].y;\n    float _7886 = fa_mesh_fs_params[20].z;\n    float _7885 = fa_mesh_fs_params[21].w;\n    float _7888 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _7882 *= _6713.y;\n            _7883 *= _6713.z;\n            _7885 *= _6702.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _7886 *= mrt.x;\n            _7888 *= mrt.w;\n        }\n    }\n    return Surface(_6606.xyz, _6606.w, _7877, clamp(fa_mesh_fs_params[5].x * _6674.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _6674.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_6713.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _6743), _7882, _7883, fa_mesh_fs_params[21].xyz, _7885, _7886, fa_mesh_fs_params[20].w, _7888, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1777 = rect.zw - rect.xy;\n    vec2 _1781 = _1777 * atlas;\n    vec2 _1785 = ddx * _1781;\n    vec2 _1789 = ddy * _1781;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1777), clamp(0.5 * log2(max(max(dot(_1785, _1785), dot(_1789, _1789)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1822 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1829;\n    if (!_1822)\n    {\n        _1829 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1829 = _1822;\n    }\n    if (_1829)\n    {\n        return;\n    }\n    vec3 _1835 = dFdx(world_pos);\n    vec3 _1838 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1842 = fa_cluster_texel(param);\n    int _1846 = int(_1842.w);\n    if (_1846 < 1)\n    {\n        return;\n    }\n    int _1856 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1856;\n    vec4 _1860 = fa_light_texel(param_1);\n    vec2 _1863 = _1860.yz;\n    int _1867 = int(_1860.w);\n    int param_2 = _1856 + 1;\n    vec4 _1872 = fa_light_texel(param_2);\n    float _1873 = _1872.x;\n    int _1879 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1883 = int(_1842.z);\n    vec3 _2148;\n    for (int k = 0; k < _1846; k++)\n    {\n        int _1896 = _1883 + k;\n        int param_3 = _1867 + (_1896 >> 2);\n        int _1913 = (_1856 + 2) + (int(fa_light_texel(param_3)[_1896 & 3]) * 7);\n        int param_4 = _1913 + 6;\n        vec4 _1918 = fa_light_texel(param_4);\n        if (((int(_1918.w + 0.5) >> _1879) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1913;\n        vec4 _1933 = fa_light_texel(param_5);\n        int param_6 = _1913 + 1;\n        vec4 _1938 = fa_light_texel(param_6);\n        int param_7 = _1913 + 2;\n        vec4 _1943 = fa_light_texel(param_7);\n        vec3 _1946 = _1933.xyz;\n        float _1951 = dot(_1946, world_pos) + _1933.w;\n        vec3 _1953 = _1938.xyz;\n        float _1958 = dot(_1953, world_pos) + _1938.w;\n        vec3 _1960 = _1943.xyz;\n        float _1965 = dot(_1960, world_pos) + _1943.w;\n        bool _1970 = abs(_1951) > 0.5;\n        bool _1978;\n        if (!_1970)\n        {\n            _1978 = abs(_1958) > 0.5;\n        }\n        else\n        {\n            _1978 = _1970;\n        }\n        bool _1986;\n        if (!_1978)\n        {\n            _1986 = abs(_1965) > 0.5;\n        }\n        else\n        {\n            _1986 = _1978;\n        }\n        if (_1986)\n        {\n            continue;\n        }\n        float _2001 = clamp(dot(geo_normal, normalize(_1960)) * _1918.z, 0.0, 1.0);\n        if (_2001 <= 0.0)\n        {\n            continue;\n        }\n        float _2021 = (clamp((0.5 - abs(_1965)) * 10.0, 0.0, 1.0) * _2001) * _1918.x;\n        vec2 _2029 = vec2(_1951 + 0.5, 0.5 - _1958);\n        vec2 _2039 = vec2(dot(_1946, _1835), dot(_1953, _1835));\n        vec2 _2049 = vec2(dot(_1946, _1838), dot(_1953, _1838));\n        int param_8 = _1913 + 5;\n        vec4 _2054 = fa_light_texel(param_8);\n        int param_9 = _1913 + 3;\n        vec4 _2059 = fa_light_texel(param_9);\n        int param_10 = _1913 + 4;\n        vec4 _2064 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2054.xyz;\n        bool _2074 = _2059.z > _2059.x;\n        if (_2074)\n        {\n            vec4 param_11 = _2059;\n            vec2 param_12 = _2029;\n            vec2 param_13 = _1863;\n            vec2 param_14 = _2039;\n            vec2 param_15 = _2049;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1873 > 0.5) && (_1873 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2100 = fa_dc_to_linear(param_16);\n                vec4 _7957 = tx;\n                _7957.x = _2100.x;\n                _7957.y = _2100.y;\n                _7957.z = _2100.z;\n                tx = _7957;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2021 * tex_a) * _2054.w, 0.0, 1.0)));\n        if (_2064.z > _2064.x)\n        {\n            vec4 param_17 = _2064;\n            vec2 param_18 = _2029;\n            vec2 param_19 = _1863;\n            vec2 param_20 = _2039;\n            vec2 param_21 = _2049;\n            vec4 _2144 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1873 > 1.5)\n            {\n                vec3 param_22 = _2144.xyz;\n                vec3 _2154 = fa_dc_to_srgb(param_22);\n                _2148 = _2154;\n            }\n            else\n            {\n                _2148 = _2144.xyz;\n            }\n            vec3 _2163 = (_2148 * 2.0) - vec3(1.0);\n            vec2 _2168 = _2163.xy * _1918.y;\n            vec3 _2190 = (normalize(_1946) * _2168.x) + (normalize(_1953) * _2168.y);\n            vec3 _2193 = normalize(normal);\n            normal = normalize(mix(_2193, normalize((_2193 * max(_2163.z, 0.0500000007450580596923828125)) + (_2190 - (_2193 * dot(_2193, _2190)))), vec3(clamp(_2021 * (_2074 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4217 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4224 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4227 = int(_4217);\n    int _4230 = int(_4224);\n    float _4240 = _4224 - float(_4230);\n    int _4295 = (_4227 * 9) + _4230;\n    int _4315 = ((_4227 + 1) * 9) + _4230;\n    return mix(mix(_4291[_4295], _4291[_4295 + 1], _4240), mix(_4291[_4315], _4291[_4315 + 1], _4240), _4217 - float(_4227));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _7800 = false;\n    float _7801 = 1.0;\n    float _7802 = 1.0;\n    float _7803 = 1.0;\n    float _7804 = 0.0;\n    float _7805 = 0.0;\n    float _7806 = 0.0;\n    float _7807 = 0.0;\n    float _7809 = 1.0;\n    bool _7810 = false;\n    vec3 _7811 = vec3(0.0);\n    float _7812 = 1.0;\n    float _7813 = 1.0;\n    float _7814 = 1.0;\n    float _7815 = 0.0;\n    float _7816 = 0.0;\n    vec3 _7817 = vec3(1.0, 0.0, 0.0);\n    vec3 _7818 = vec3(0.0, 0.0, 1.0);\n    float _7819 = 1.0;\n    float _7820 = 1.0;\n    float _4366 = clamp(s.specular, 0.0, 1.0);\n    float _4370 = clamp(s.ior, 1.0, 3.0);\n    bool _4375 = (_4366 != 1.0) || (_4370 != 1.5);\n    bool _4384;\n    if (!_4375)\n    {\n        _4384 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4384 = _4375;\n    }\n    if (_4384)\n    {\n        float _4392 = (_4370 - 1.0) / (_4370 + 1.0);\n        f0 = mix(min(vec3(_4392 * _4392) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4366, s.albedo, vec3(metallic));\n        _7801 = mix(_4366, 1.0, metallic);\n        _7800 = true;\n    }\n    float _4419 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4419 > 0.0)\n    {\n        float _4427 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _7804 = _4419;\n        _7805 = _4427;\n        float _4434 = _4427 * _4427;\n        _7806 = _4434;\n        _7807 = _4434 * _4434;\n        float _4446 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _7809 = _4446;\n        _7802 = 1.0 - (_4419 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4446, 0.0, 1.0), 5.0))));\n        _7800 = true;\n    }\n    vec3 _4465 = max(s.sheen_color, vec3(0.0));\n    float _4474 = max(_4465.x, max(_4465.y, _4465.z));\n    if (_4474 > 0.0)\n    {\n        float _4482 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _7810 = true;\n        _7811 = _4465;\n        _7812 = _4482;\n        _7813 = _4482 * _4482;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4482;\n        float _4499 = fa_sheen_albedo(param, param_1);\n        _7815 = _4499;\n        _7814 = 1.0 - min(_4474 * _4499, 1.0);\n        _7800 = true;\n    }\n    _7803 = _7802 * _7814;\n    float _4518 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4518 != 0.0)\n    {\n        vec3 _4533 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4533;\n        if (dot(_4533, _4533) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4545 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4545.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4545.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4545.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4549 = t;\n        vec3 _4550 = normalize(_4549);\n        t = _4550;\n        vec3 _4575 = normalize((_4550 * cos(s.anisotropy_rotation)) + ((cross(n, _4550) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _7817 = _4575;\n        _7818 = cross(n, _4575);\n        float _4585 = roughness * roughness;\n        float _4591 = mix(_4585, 1.0, _4518 * _4518);\n        bool _4593 = _4518 > 0.0;\n        _7819 = _4593 ? _4591 : _4585;\n        _7820 = _4593 ? _4585 : _4591;\n        _7816 = _4518;\n        _7800 = true;\n    }\n    return FaLayers(_7800, _7801, _7802, _7803, _7804, _7805, _7806, _7807, i.world_normal, _7809, _7810, _7811, _7812, _7813, _7814, _7815, _7816, _7817, _7818, _7819, _7820);\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[39].y > 0.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3388 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3388;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _3998 = (1.0 - fa_mesh_fs_params[40].w) - fa_mesh_fs_params[45].w;\n    vec3 amb = vec3(0.0);\n    bool _4003 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_3998 > 0.0005000000237487256526947021484375)\n    {\n        if (_4003)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[39].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3998;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _3998;\n        }\n    }\n    bool _4054 = fa_mesh_fs_params[40].w > 0.0;\n    if (_4054)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[40].xy;\n            float param_4 = fa_mesh_fs_params[40].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[40].w);\n        }\n    }\n    bool _4085 = fa_mesh_fs_params[45].w > 0.0;\n    if (_4085)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[45].xy;\n            float param_7 = fa_mesh_fs_params[45].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[45].w);\n        }\n    }\n    if ((_4003 || _4054) || _4085)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[30].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 30].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[30].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5359;\n    if (fa_lm.z > 0.5)\n    {\n        _5359 = 0.0;\n    }\n    else\n    {\n        _5359 = 1.0 - clamp(fa_mesh_fs_params[30].w, 0.0, 1.0);\n    }\n    bool _5370 = _5359 < 1.0;\n    bool _5376;\n    if (_5370)\n    {\n        int param = li;\n        _5376 = fa_light_baked(param);\n    }\n    else\n    {\n        _5376 = _5370;\n    }\n    return _5376 ? _5359 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _795 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _808 = (c - (ru * hx)) - p;\n        vec3 _814 = ru * (2.0 * hx);\n        float _820 = max(dot(_814, _814), 9.9999999392252902907785028219223e-09);\n        float _824 = dot(_808, _814);\n        float t = clamp((-_824) / _820, 0.0, 1.0);\n        if (_795)\n        {\n            float _839 = dot(r, _814);\n            float _845 = _820 - (_839 * _839);\n            if (abs(_845) > (9.9999997473787516355514526367188e-06 * _820))\n            {\n                t = clamp(((dot(r, _808) * _839) - _824) / _845, 0.0, 1.0);\n            }\n        }\n        return (p + _808) + (_814 * t);\n    }\n    vec3 q = p;\n    float _877 = dot(r, axis);\n    bool _885;\n    if (_795)\n    {\n        _885 = abs(_877) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _885 = _795;\n    }\n    if (_885)\n    {\n        float _895 = dot(c - p, axis) / _877;\n        if (_895 > 0.0)\n        {\n            q = p + (r * _895);\n        }\n    }\n    vec3 _908 = q - c;\n    vec2 xy = vec2(dot(_908, ru), dot(_908, uu));\n    if (shape > 0.5)\n    {\n        float _923 = length(xy);\n        if (_923 > hx)\n        {\n            xy *= (hx / _923);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _556 = abs(d);\n    float _558 = _556.x;\n    float _560 = _556.y;\n    bool _561 = _558 >= _560;\n    bool _569;\n    if (_561)\n    {\n        _569 = _558 >= _556.z;\n    }\n    else\n    {\n        _569 = _561;\n    }\n    int _570;\n    if (_569)\n    {\n        _570 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _585;\n        if (_560 >= _556.z)\n        {\n            _585 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _585 = (d.z > 0.0) ? 4 : 5;\n        }\n        _570 = _585;\n    }\n    return _570;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _715 = dot(d, right);\n    float _719 = dot(d, up);\n    float _730;\n    if (((_715 * _715) + (_719 * _719)) > 1.0000000133514319600180897396058e-10)\n    {\n        _730 = atan(_719, _715) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _730 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_730 - floor(_730)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _961 = fa_light_base(param);\n    bool _965 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _961;\n    vec4 _969 = fa_light_texel(param_1);\n    int param_2 = _961 + 1;\n    vec4 _974 = fa_light_texel(param_2);\n    float _977 = _974.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _989 = _965 && (_977 > 2.5);\n    fa_light_is_area = _989;\n    bool _991 = _977 < 0.5;\n    vec3 l;\n    if (_991)\n    {\n        l = normalize(_969.xyz);\n        if (_965)\n        {\n            int param_3 = _961 + 6;\n            vec4 _1005 = fa_light_texel(param_3);\n            if (_1005.z > 0.5)\n            {\n                int param_4 = _961 + 4;\n                vec4 _1015 = fa_light_texel(param_4);\n                int param_5 = _961 + 5;\n                vec4 _1020 = fa_light_texel(param_5);\n                vec2 param_6 = _1005.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1015.xyz) * _1015.w, (-dot(world_pos, _1020.xyz)) * _1020.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1050 = _969.xyz;\n        vec3 _1052 = _1050 - world_pos;\n        vec3 to_light = _1052;\n        float _1055 = length(_1052);\n        float reach = _1055;\n        bool front = true;\n        if (_989)\n        {\n            int param_8 = _961 + 7;\n            reach = max(_1055 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _961 + 4;\n            vec4 _1079 = fa_light_texel(param_9);\n            int param_10 = _961 + 5;\n            vec4 _1084 = fa_light_texel(param_10);\n            int param_11 = _961 + 6;\n            vec4 _1089 = fa_light_texel(param_11);\n            float _1090 = _1089.w;\n            int param_12 = _961 + 2;\n            vec3 _1097 = normalize(fa_light_texel(param_12).xyz);\n            bool _1099 = _1090 > 1.5;\n            bool _1107;\n            if (!_1099)\n            {\n                _1107 = dot(_1097, to_light) < 0.0;\n            }\n            else\n            {\n                _1107 = _1099;\n            }\n            front = _1107;\n            vec3 r = vec3(0.0);\n            vec3 _1116 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1120 = dot(n, n) > 0.5;\n            bool _1128;\n            if (_1120)\n            {\n                _1128 = dot(_1116, _1116) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1128 = _1120;\n            }\n            if (_1128)\n            {\n                r = reflect(-normalize(_1116), normalize(n));\n            }\n            vec3 param_13 = _1050;\n            vec3 param_14 = _1097;\n            vec3 param_15 = _1079.xyz;\n            vec3 param_16 = _1084.xyz;\n            float param_17 = _1079.w;\n            float param_18 = _1084.w;\n            float param_19 = _1090;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1164 = length(to_light);\n        dist = _1164;\n        l = to_light / vec3(max(_1164, 9.9999997473787516355514526367188e-05));\n        float _1178 = reach / max(_969.w, 0.001000000047497451305389404296875);\n        float _1184 = clamp(1.0 - (_1178 * _1178), 0.0, 1.0);\n        float _1186;\n        if (front)\n        {\n            _1186 = _1184 * _1184;\n        }\n        else\n        {\n            _1186 = 0.0;\n        }\n        atten = _1186;\n        bool _1197 = _977 < 2.5;\n        if ((_977 > 1.5) && _1197)\n        {\n            int param_22 = _961 + 2;\n            vec4 _1205 = fa_light_texel(param_22);\n            float _1215 = _1205.w;\n            int param_23 = _961 + 3;\n            vec4 _1220 = fa_light_texel(param_23);\n            float _1221 = _1220.x;\n            float cos_inner = _1221;\n            if (_1221 > 1.5)\n            {\n                cos_inner = mix(_1215, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1215, cos_inner, dot(-l, normalize(_1205.xyz)));\n        }\n        if (_965 && (_977 < 1.5))\n        {\n            int param_24 = _961 + 6;\n            vec4 _1245 = fa_light_texel(param_24);\n            if (_1245.z > 0.5)\n            {\n                vec3 _1253 = -to_light;\n                int param_25 = _961 + 4;\n                int param_26 = _961 + 5;\n                vec3 _1267 = fa_light_texel(param_25).xyz;\n                vec3 _1271 = fa_light_texel(param_26).xyz;\n                vec3 _1280 = vec3(dot(_1253, _1267), dot(_1253, _1271), dot(_1253, cross(_1267, _1271)));\n                vec3 param_27 = _1280;\n                int _1284 = fa_cube_face(param_27);\n                int param_28 = _1284;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1311 = vec2(dot(_1280, cross(param_29, param_30)), dot(_1280, param_30)) / vec2(max(dot(_1280, param_29), 9.9999997473787516355514526367188e-05));\n                int _1315 = _1284 / 3;\n                vec2 param_31 = _1245.xy + (vec2(float(_1284 - (_1315 * 3)), float(_1315)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1311.x), 0.5 - (0.5 * _1311.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _961 + 7;\n            vec4 _1345 = fa_light_texel(param_33);\n            if (_1345.z > 0.5)\n            {\n                int param_34 = _961 + 2;\n                int param_35 = _961 + 4;\n                int param_36 = _961 + 5;\n                vec2 param_37 = _1345.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_965 && _1197)\n            {\n                int param_42 = _961 + 6;\n                vec4 _1392 = fa_light_texel(param_42);\n                int param_43 = _961 + 7;\n                vec4 _1397 = fa_light_texel(param_43);\n                bool _1400 = _1392.z > 0.5;\n                bool _1407;\n                if (!_1400)\n                {\n                    _1407 = _1397.z > 0.5;\n                }\n                else\n                {\n                    _1407 = _1400;\n                }\n                if (_1407)\n                {\n                    int param_44 = _961 + 2;\n                    vec4 _1414 = fa_light_texel(param_44);\n                    vec3 _1418 = normalize(_1414.xyz);\n                    int param_45 = _961 + 4;\n                    vec4 _1423 = fa_light_texel(param_45);\n                    int param_46 = _961 + 5;\n                    vec4 _1428 = fa_light_texel(param_46);\n                    if (_1400)\n                    {\n                        vec3 _1436 = -to_light;\n                        float _1443 = _1414.w;\n                        float _1459 = 0.5 / max(dot(_1436, _1418) * (sqrt(max(1.0 - (_1443 * _1443), 0.0)) / max(_1443, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1392.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1436, _1423.xyz) * _1459), 0.5 - (dot(_1436, _1428.xyz) * _1459));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1397.z > 0.5)\n                    {\n                        vec2 param_49 = _1397.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1418;\n                        vec3 param_52 = _1423.xyz;\n                        vec3 param_53 = _1428.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _7788 = _974.xyz * atten;\n    if (_965)\n    {\n        _7788 *= fa_light_tint;\n    }\n    int _1528;\n    if (_991)\n    {\n        _1528 = 0;\n    }\n    else\n    {\n        _1528 = ((_977 > 1.5) && (_977 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _7788, atten, 1.0, dist, _1528);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2265;\n    if (i == 0)\n    {\n        _2265 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2281;\n        if (i == 1)\n        {\n            _2281 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2289;\n            if (i == 2)\n            {\n                _2289 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2289 = fa_shadows[24].w;\n            }\n            _2281 = _2289;\n        }\n        _2265 = _2281;\n    }\n    return _2265;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2322 = fa_shadow_depth(param, param_1);\n    float _2326;\n    if (conv.x < 0.5)\n    {\n        _2326 = _2322;\n    }\n    else\n    {\n        _2326 = (conv.y * conv.z) / (conv.z - (_2322 * (conv.z - conv.y)));\n    }\n    return _2326;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2253 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2253), sin(_2253)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2372 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2381;\n        if (k < 0.0)\n        {\n            _2381 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2381 = k;\n        }\n        float _2401 = clamp((_2381 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2372;\n            vec2 _2420 = fa_shadow_vogel(param_3, param_4, param_5) * _2401;\n            vec2 param_6 = uv + (_2420 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2432 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2432 < (zr - (length(_2420) * plane)))\n            {\n                sum += _2432;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2458 = sum / cnt;\n        float _2468;\n        if (k < 0.0)\n        {\n            _2468 = (-k) / max(_2458, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2468 = k;\n        }\n        radius = clamp(((max(zr - _2458, 0.0) * unit) * _2468) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2490 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2490; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2490;\n        float param_11 = _2372;\n        vec2 _2509 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2509 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2509) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2490);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2551 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2556 = clamp(dot(n, l), 0.0, 1.0);\n    float _2562 = sqrt(1.0 - (_2556 * _2556));\n    float _2569 = min(_2562 / max(_2556, 0.20000000298023223876953125), 4.0);\n    float _2574;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2574 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2574 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2599 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2574 * _2562)), 1.0);\n    float _2606 = _2599.x;\n    bool _2609 = _2606 < fa_shadows[ci * 1 + 16].x;\n    bool _2618;\n    if (!_2609)\n    {\n        _2618 = _2606 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2618 = _2609;\n    }\n    bool _2627;\n    if (!_2618)\n    {\n        _2627 = _2599.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2627 = _2618;\n    }\n    bool _2636;\n    if (!_2627)\n    {\n        _2636 = _2599.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2636 = _2627;\n    }\n    bool _2643;\n    if (!_2636)\n    {\n        _2643 = _2599.z > 1.0;\n    }\n    else\n    {\n        _2643 = _2636;\n    }\n    if (_2643)\n    {\n        return -1.0;\n    }\n    float _2651;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2651 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2651 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2599.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2599.z - ((_2651 * (1.0 + (0.5 * _2569))) / _2551);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2551;\n    float param_5 = _2551 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2569, 3.0)) * 0.5) / _2551;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3029 = int(fa_shadows[25].x + 0.5);\n    if (_3029 < 1)\n    {\n        return 1.0;\n    }\n    float _3044 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3029 - 1;\n    if (_3044 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3056 = _3029 > 1;\n    bool _3063;\n    if (_3056)\n    {\n        _3063 = _3044 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3063 = _3056;\n    }\n    if (_3063)\n    {\n        ci = 1;\n    }\n    bool _3067 = _3029 > 2;\n    bool _3074;\n    if (_3067)\n    {\n        _3074 = _3044 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3074 = _3067;\n    }\n    if (_3074)\n    {\n        ci = 2;\n    }\n    bool _3078 = _3029 > 3;\n    bool _3085;\n    if (_3078)\n    {\n        _3085 = _3044 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3085 = _3078;\n    }\n    if (_3085)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _3029)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3111 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3111;\n        if (_3111 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _3136;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3136 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3136 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _3155 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3136, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _3166 = clamp((_3044 - (fa_shadow_split_at(param_7) - _3155)) / _3155, 0.0, 1.0);\n        if (_3166 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _3029)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _3187 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3187;\n                if (_3187 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _3166);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2709 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2716;\n    if (!_2709)\n    {\n        _2716 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2716 = _2709;\n    }\n    if (_2716)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2729 = fa_light_texel(param);\n    float _2730 = _2729.x;\n    if (_2730 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2739 = int(_2730 + 0.5);\n    int param_1 = _2739;\n    vec4 _2743 = fa_light_texel(param_1);\n    int param_2 = _2739 + 1;\n    vec4 _2748 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2751 = _2743.y;\n    if (_2751 > 0.0)\n    {\n        float _2768 = 1.0 - smoothstep(0.75 * _2751, _2751, length(world - fa_shadows[27].xyz));\n        fade = _2768;\n        if (_2768 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2743.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2792 = (_2739 + 2) + (face * 6);\n    int param_4 = _2792;\n    int param_5 = _2792 + 1;\n    int param_6 = _2792 + 3;\n    vec4 _2806 = fa_light_texel(param_6);\n    int param_7 = _2792 + 4;\n    vec4 _2811 = fa_light_texel(param_7);\n    int param_8 = _2792 + 5;\n    vec4 _2816 = fa_light_texel(param_8);\n    float _2828 = _2816.x * max(dot(_2806, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2833 = clamp(dot(n, l), 0.0, 1.0);\n    float _2856 = clamp(dot(n, _2806.xyz), -1.0, 1.0);\n    float _2875 = min(sqrt(1.0 - (_2856 * _2856)) / max(abs(dot(n, world - lpos)) / max(dot(_2806, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2878 = _2748.y;\n    float _2880;\n    if (_2878 > 0.0)\n    {\n        _2880 = _2878;\n    }\n    else\n    {\n        _2880 = 1.5 * _2828;\n    }\n    vec4 _2900 = vec4(world + (n * (_2880 * sqrt(1.0 - (_2833 * _2833)))), 1.0);\n    float _2904 = dot(_2806, _2900);\n    float _2907 = _2816.y;\n    if (_2904 < _2907)\n    {\n        return 1.0;\n    }\n    vec2 _2922 = vec2(dot(fa_light_texel(param_4), _2900), dot(fa_light_texel(param_5), _2900)) / vec2(_2904);\n    float _2924 = _2922.x;\n    bool _2927 = _2924 < _2811.x;\n    bool _2936;\n    if (!_2927)\n    {\n        _2936 = _2924 > _2811.z;\n    }\n    else\n    {\n        _2936 = _2927;\n    }\n    bool _2945;\n    if (!_2936)\n    {\n        _2945 = _2922.y < _2811.y;\n    }\n    else\n    {\n        _2945 = _2936;\n    }\n    bool _2954;\n    if (!_2945)\n    {\n        _2954 = _2922.y > _2811.w;\n    }\n    else\n    {\n        _2954 = _2945;\n    }\n    if (_2954)\n    {\n        return 1.0;\n    }\n    float _2960 = _2748.x;\n    float _2962;\n    if (_2960 > 0.0)\n    {\n        _2962 = _2960;\n    }\n    else\n    {\n        _2962 = 1.5 * _2828;\n    }\n    vec2 param_9 = _2922;\n    vec4 param_10 = _2811;\n    float param_11 = _2904 - (_2962 * (1.0 + (0.5 * _2875)));\n    float param_12 = _2828;\n    float param_13 = 1.0;\n    float param_14 = _2816.z * 0.25;\n    float param_15 = (_2828 * min(_2875, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2907, _2816.z);\n    int param_17 = int(_2743.z + 0.5);\n    float param_18 = _2743.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5103 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5110;\n    if (!_5103)\n    {\n        _5110 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5110 = _5103;\n    }\n    if (_5110)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5123 = fa_light_texel(param);\n    float _5124 = _5123.y;\n    float len = _5124;\n    if (_5124 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5136 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5146 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5136);\n    if (_5146 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5152 = len;\n    float _5155 = min(_5152, 0.89999997615814208984375 * dist);\n    len = _5155;\n    float _5160 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5136);\n    float _5165 = _5160 + (0.5 * _5155);\n    vec3 _5171 = world + (gn * _5160);\n    float _5173 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5237;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5188 = (float(k) + _5173) * 0.083333335816860198974609375;\n        vec3 _5196 = _5171 + (l * (_5188 * len));\n        vec4 _5202 = vec4(_5196, 1.0);\n        float _5208 = dot(fa_mesh_fs_params[28], _5202);\n        if (_5208 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5228 = vec2(dot(fa_mesh_fs_params[26], _5202), dot(fa_mesh_fs_params[27], _5202)) / vec2(_5208);\n        float _5232 = _5228.x * 0.5;\n        float _5233 = _5232 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5237 = (_5228.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5237 = 0.5 - (_5228.y * 0.5);\n        }\n        bool _5253 = _5233 < 0.0;\n        bool _5260;\n        if (!_5253)\n        {\n            _5260 = _5233 >= 1.0;\n        }\n        else\n        {\n            _5260 = _5253;\n        }\n        bool _5267;\n        if (!_5260)\n        {\n            _5267 = _5237 < 0.0;\n        }\n        else\n        {\n            _5267 = _5260;\n        }\n        bool _5274;\n        if (!_5267)\n        {\n            _5274 = _5237 >= 1.0;\n        }\n        else\n        {\n            _5274 = _5267;\n        }\n        if (_5274)\n        {\n            break;\n        }\n        vec4 _5293 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_5233, _5237) * fa_mesh_fs_params[24].zw), 0);\n        if (_5293.w < 0.5)\n        {\n            continue;\n        }\n        float _5312 = (dot(fa_mesh_fs_params[29].xyz, _5196) + fa_mesh_fs_params[29].w) - _5293.x;\n        if ((_5312 > _5160) && (_5312 < _5165))\n        {\n            occ = max(occ, (1.0 - (_5188 * _5188)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5233, 0.5 - _5232), min(_5237, 1.0 - _5237))));\n        }\n    }\n    return 1.0 - (occ * _5146);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _5415 = fa_baked_keep(param);\n    if (_5415 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5441 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _7857 = _5441.color;\n    float _7858 = _5441.attenuation;\n    float _7859 = _5441.shadow;\n    bool _5444 = _5441.type == 0;\n    if (_5444 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5441.direction;\n        float _5455 = fa_shadow_factor(param_5, param_6);\n        _7859 = _5455;\n        _7857 *= _5455;\n    }\n    else\n    {\n        bool _5466 = _5441.type != 0;\n        bool _5472;\n        if (_5466)\n        {\n            _5472 = _7858 > 0.0;\n        }\n        else\n        {\n            _5472 = _5466;\n        }\n        if (_5472)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5441.direction;\n            float _5491 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _7859 = _5491;\n            _7857 *= _5491;\n        }\n    }\n    bool _5501 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5507;\n    if (_5501)\n    {\n        _5507 = _7858 > 0.0;\n    }\n    else\n    {\n        _5507 = _5501;\n    }\n    if (_5507)\n    {\n        float _5514;\n        if (_5444)\n        {\n            _5514 = 1000000000.0;\n        }\n        else\n        {\n            _5514 = _5441._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5441.direction;\n        float param_18 = _5514;\n        float _5532 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _7859 *= _5532;\n        _7857 *= _5532;\n    }\n    float _5545 = _7858;\n    float _5546 = _5545 * _5415;\n    _7858 = _5546;\n    vec3 _5550 = _7857;\n    vec3 _5551 = _5550 * _5415;\n    _7857 = _5551;\n    return LightSample(_5441.direction, _5551, _5546, _7859, _5441._distance, _5441.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _5585 = v - (n * dot(v, n));\n    vec3 t = _5585;\n    float _5589 = dot(_5585, _5585);\n    float l2 = _5589;\n    if (_5589 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _5599;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _5599 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _5599 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _5599;\n        l2 = dot(_5599, _5599);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _5634 = dot(a, a);\n    float _5638 = dot(b, b);\n    if ((_5634 < 1.0000000195414813782625560981111e-24) || (_5638 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _5652 = a * inversesqrt(_5634);\n    vec3 _5657 = b * inversesqrt(_5638);\n    float _5661 = dot(_5652, _5657);\n    float _5664 = abs(_5661);\n    float g = (((((((((((0.0416471660137176513671875 * _5664) - 0.1924748718738555908203125) * _5664) + 0.4179156124591827392578125) * _5664) - 0.616057217121124267578125) * _5664) + 0.777722418308258056640625) * _5664) - 0.999542415142059326171875) * _5664) + 1.570791721343994140625;\n    if (_5661 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_5661 * _5661), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_5652, _5657) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _5721 = a.z > 0.0;\n    bool _5725 = b.z > 0.0;\n    if (_5721 && _5725)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_5721 != _5725)\n        {\n            vec3 _5760 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _5760.z = 0.0;\n            if (_5721)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _5760;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _5760;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _5760;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _5760;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _5809 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _5835 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _5861 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _5887 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _5809;\n    vec3 param_1 = _5835;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _5835;\n    vec3 param_7 = _5861;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _5861;\n    vec3 param_13 = _5887;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _5887;\n    vec3 param_19 = _5809;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nfloat fa_ltc_rect(vec4 abcd, vec3 center, vec3 ex, vec3 ey)\n{\n    vec4 param = abcd;\n    vec3 param_1 = (center - ex) - ey;\n    vec3 param_2 = (center + ex) - ey;\n    vec3 param_3 = (center + ex) + ey;\n    vec3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    if ((shape < 0.5) || (shape > 1.5))\n    {\n        vec4 param = m;\n        vec3 param_1 = pc;\n        vec3 param_2 = ex;\n        vec3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    vec3 _6037 = (pc + (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _6061 = (pc - (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _6077 = (pc - (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec4 param_4 = m;\n    vec3 param_5 = _6037;\n    vec3 param_6 = (pc + (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_7 = (pc - (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_8 = _6061;\n    vec4 param_9 = m;\n    vec3 param_10 = _6037;\n    vec3 param_11 = _6061;\n    vec3 param_12 = (pc - (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    vec3 param_13 = _6077;\n    vec4 param_14 = m;\n    vec3 param_15 = _6037;\n    vec3 param_16 = _6077;\n    vec3 param_17 = (pc + (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec3 param_18 = (pc + (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _6135 = fa_light_base(param);\n    int param_1 = _6135;\n    int param_2 = _6135 + 1;\n    int param_3 = _6135 + 2;\n    int param_4 = _6135 + 4;\n    vec4 _6157 = fa_light_texel(param_4);\n    int param_5 = _6135 + 5;\n    vec4 _6162 = fa_light_texel(param_5);\n    int param_6 = _6135 + 6;\n    vec4 _6167 = fa_light_texel(param_6);\n    float _6168 = _6167.w;\n    vec3 _6173 = fa_light_texel(param_1).xyz - world_pos;\n    bool _6175 = _6168 < 1.5;\n    bool _6182;\n    if (_6175)\n    {\n        _6182 = dot(normalize(fa_light_texel(param_3).xyz), _6173) >= 0.0;\n    }\n    else\n    {\n        _6182 = _6175;\n    }\n    if (_6182)\n    {\n        return vec3(0.0);\n    }\n    bool _6191 = (_6168 > 0.5) && _6175;\n    float _6195 = _6191 ? 1.0539000034332275390625 : 1.0;\n    vec3 _6198 = _6157.xyz;\n    float _6200 = _6157.w;\n    vec3 _6206 = _6162.xyz;\n    float _6208 = _6162.w;\n    vec3 up = _6206 * (_6208 * _6195);\n    float _6214;\n    if (_6191)\n    {\n        _6214 = (3.1415927410125732421875 * _6200) * _6200;\n    }\n    else\n    {\n        _6214 = (4.0 * _6200) * _6208;\n    }\n    if (_6168 > 1.5)\n    {\n        vec3 _6240 = cross(_6198, -_6173);\n        vec3 perp = _6240;\n        float _6244 = dot(_6240, _6240);\n        vec3 _6247;\n        if (_6244 > 1.0000000133514319600180897396058e-10)\n        {\n            _6247 = perp * inversesqrt(_6244);\n        }\n        else\n        {\n            _6247 = _6206;\n        }\n        perp = _6247;\n        up = _6247 * _6208;\n    }\n    float _6268 = max(_6214, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _6278 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _6278;\n    vec3 param_10 = n;\n    vec3 param_11 = _6173;\n    vec3 _6286 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_12 = _6278;\n    vec3 param_13 = n;\n    vec3 param_14 = _6198 * (_6200 * _6195);\n    vec3 _6294 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_15 = _6278;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    vec3 _6302 = fa_ltc_local(param_15, param_16, param_17);\n    vec4 param_18 = vec4(1.0, 0.0, 0.0, 1.0);\n    float param_19 = _6168;\n    vec3 param_20 = _6286;\n    vec3 param_21 = _6294;\n    vec3 param_22 = _6302;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    vec2 _6321 = fa_ltc_uv(param_23, param_24) * 64.0;\n    vec2 param_25 = _6321;\n    vec2 param_26 = _6321 + vec2(64.0, 0.0);\n    vec4 _6331 = fa_atlas_fetch(param_26);\n    vec4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _6168;\n    vec3 param_29 = _6286;\n    vec3 param_30 = _6294;\n    vec3 param_31 = _6302;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _6331.x) + ((vec3(f90) - f0) * _6331.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_6173, _6173)) + _6268) / _6268) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4840 = 1.0 / alpha;\n    return ((2.0 + _4840) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _4840)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _4875 = max(dot(L.nc, l), 0.0);\n    float _4881 = max(dot(L.nc, h), 0.0);\n    float _4890 = ((_4881 * _4881) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _4890) * _4890)) * (0.5 / max(mix((2.0 * _4875) * L.coat_ndv, _4875 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4875)) * _4875;\n}\n\nvec3 fa_area_layers(FaLayers L, int li, vec3 world_pos, vec3 n, vec3 v, vec3 l, vec3 diffuse_color, vec3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    vec3 param_2 = n;\n    vec3 param_3 = v;\n    vec3 param_4 = diffuse_color;\n    vec3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _6399;\n    if (L.sheen_on)\n    {\n        _6399 = L.sheen_scale;\n    }\n    else\n    {\n        _6399 = 1.0;\n    }\n    vec3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _6399);\n    vec3 _6412 = normalize(l + v);\n    int param_10 = li;\n    vec3 _6423 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _6432 = max(dot(n, l), 0.0);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _6412), 0.0);\n        float param_13 = _6432;\n        float param_14 = ndv;\n        result += ((L.sheen * _6423) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _6432)) * _6432) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_15 = L;\n        vec3 param_16 = l;\n        vec3 param_17 = _6412;\n        float param_18 = max(dot(v, _6412), 0.0);\n        result += (_6423 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4743 = tdh / at;\n    float _4747 = bdh / ab;\n    float _4759 = ((_4743 * _4743) + (_4747 * _4747)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _4759) * _4759);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4939 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5018 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _5018) * _5018);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _4939);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _4939));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4149 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4152 = _4149.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4152 * _4152, exp2((-9.27999973297119140625) * ndv)) * _4152) + _4149.y)) + _4149.zw;\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3408 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3411 = _3408.x;\n    float _3413 = _3408.z;\n    vec2 e = vec2(_3411, _3413);\n    if (_3408.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3413)) * ((_3411 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3411)) * ((_3413 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3460;\n    if (lv == 0)\n    {\n        _3460 = 0.0;\n    }\n    else\n    {\n        _3460 = res + 2.0;\n    }\n    float _3470;\n    if (lv == 0)\n    {\n        _3470 = 0.0;\n    }\n    else\n    {\n        _3470 = (res - (res / float(1 << (lv - 1)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3460, _3470)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3515;\n    if (res > 64.5)\n    {\n        _3515 = 5.0;\n    }\n    else\n    {\n        _3515 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3530 = clamp(rough, 0.0, 1.0) * (_3515 - 1.0);\n    int _3537 = int(min(floor(_3530), _3515 - 2.0));\n    float _3542 = _3530 - float(_3537);\n    vec3 param = d;\n    vec2 _3546 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3537;\n    vec2 param_4 = _3546;\n    vec3 _3556 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3542 < 0.00200000009499490261077880859375)\n    {\n        return _3556;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3537 + 1;\n    vec2 param_8 = _3546;\n    return mix(_3556, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3542));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3626 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3633 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3640 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3646 = dot(bx.xyz, d);\n    float _3650 = dot(by.xyz, d);\n    float _3654 = dot(bz.xyz, d);\n    float _3660;\n    if (_3646 > 9.9999999747524270787835121154785e-07)\n    {\n        _3660 = (1.0 - _3626) / _3646;\n    }\n    else\n    {\n        float _3674;\n        if (_3646 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3674 = ((-1.0) - _3626) / _3646;\n        }\n        else\n        {\n            _3674 = 1000000015047466219876688855040.0;\n        }\n        _3660 = _3674;\n    }\n    float tx = _3660;\n    float _3691;\n    if (_3650 > 9.9999999747524270787835121154785e-07)\n    {\n        _3691 = (1.0 - _3633) / _3650;\n    }\n    else\n    {\n        float _3704;\n        if (_3650 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3704 = ((-1.0) - _3633) / _3650;\n        }\n        else\n        {\n            _3704 = 1000000015047466219876688855040.0;\n        }\n        _3691 = _3704;\n    }\n    float ty = _3691;\n    float _3720;\n    if (_3654 > 9.9999999747524270787835121154785e-07)\n    {\n        _3720 = (1.0 - _3640) / _3654;\n    }\n    else\n    {\n        float _3733;\n        if (_3654 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3733 = ((-1.0) - _3640) / _3654;\n        }\n        else\n        {\n            _3733 = 1000000015047466219876688855040.0;\n        }\n        _3720 = _3733;\n    }\n    float _3745 = tx;\n    float _3748 = (_3745 > 0.0) ? _3745 : 1000000015047466219876688855040.0;\n    tx = _3748;\n    float _3749 = ty;\n    float _3752 = (_3749 > 0.0) ? _3749 : 1000000015047466219876688855040.0;\n    ty = _3752;\n    float _3762 = min(_3748, min(_3752, (_3720 > 0.0) ? _3720 : 1000000015047466219876688855040.0));\n    if (_3762 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _3778 = (fa_world_pos + (d * _3762)) - posw.xyz;\n    vec3 _3783;\n    if (dot(_3778, _3778) > 1.0000000133514319600180897396058e-10)\n    {\n        _3783 = normalize(_3778);\n    }\n    else\n    {\n        _3783 = d;\n    }\n    return _3783;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _3829 = (1.0 - fa_mesh_fs_params[40].w) - fa_mesh_fs_params[45].w;\n    vec3 outc = vec3(0.0);\n    if (_3829 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[39].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3858 = rough * rough;\n            float _3889 = 0.60000002384185791015625 * _3858;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3858)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3889, 0.0500000007450580596923828125 + _3889, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3858 * 0.60000002384185791015625));\n        }\n        outc = base * _3829;\n    }\n    if (fa_mesh_fs_params[40].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[40];\n        vec4 param_5 = fa_mesh_fs_params[41];\n        vec4 param_6 = fa_mesh_fs_params[42];\n        vec4 param_7 = fa_mesh_fs_params[43];\n        vec4 param_8 = fa_mesh_fs_params[44];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _3948 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_3948 * fa_mesh_fs_params[40].w);\n    }\n    if (fa_mesh_fs_params[45].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[45];\n        vec4 param_12 = fa_mesh_fs_params[46];\n        vec4 param_13 = fa_mesh_fs_params[47];\n        vec4 param_14 = fa_mesh_fs_params[48];\n        vec4 param_15 = fa_mesh_fs_params[49];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _3980 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_3980 * fa_mesh_fs_params[45].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4626;\n        if (L.aniso >= 0.0)\n        {\n            _4626 = L.b;\n        }\n        else\n        {\n            _4626 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4626, v), _4626), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4659 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4659.x) + (vec3(L.f90) * _4659.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4714 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4714.x) + _4714.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4191 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4191.x) + vec3(_4191.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3211 = int(fa_shadows[25].x + 0.5);\n    float _3221 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint_1 = vec3(0.3499999940395355224609375);\n    bool _3226 = _3211 > 0;\n    bool _3235;\n    if (_3226)\n    {\n        int param = _3211 - 1;\n        _3235 = _3221 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3235 = _3226;\n    }\n    if (_3235)\n    {\n        tint_1 = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3241 = _3211 > 1;\n        bool _3248;\n        if (_3241)\n        {\n            _3248 = _3221 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3248 = _3241;\n        }\n        if (_3248)\n        {\n            tint_1 = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3254 = _3211 > 2;\n        bool _3261;\n        if (_3254)\n        {\n            _3261 = _3221 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3261 = _3254;\n        }\n        if (_3261)\n        {\n            tint_1 = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3267 = _3211 > 3;\n        bool _3274;\n        if (_3267)\n        {\n            _3274 = _3221 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3274 = _3267;\n        }\n        if (_3274)\n        {\n            tint_1 = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint_1, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _7557 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _7557 = -_7557;\n    }\n    vec3 _6920 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _7557, fa_world_tangent, fa_uv, fa_vertex_color, _6920, gl_FrontFacing);\n    Surface _6928 = fa_standard_surface(param_1);\n    vec3 _7588 = _6928.albedo;\n    float _7589 = _6928.alpha;\n    vec3 _7590 = _6928.normal;\n    float _7591 = _6928.metallic;\n    float _7592 = _6928.roughness;\n    float _7593 = _6928.occlusion;\n    vec3 _7594 = _6928.emission;\n    float _7595 = _6928.clearcoat;\n    float _7596 = _6928.clearcoat_roughness;\n    vec3 _7597 = _6928.sheen_color;\n    float _7598 = _6928.sheen_roughness;\n    float _7599 = _6928.anisotropy;\n    float _7600 = _6928.anisotropy_rotation;\n    float _7601 = _6928.specular;\n    float _7602 = _6928.ior;\n    vec3 _7603 = _6928.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _7557, fa_world_tangent, fa_uv, fa_vertex_color, _6920, gl_FrontFacing);\n    Surface param_3 = _6928;\n    surface(param_2, param_3);\n    _7588 = param_3.albedo;\n    _7589 = param_3.alpha;\n    _7590 = param_3.normal;\n    _7591 = param_3.metallic;\n    _7592 = param_3.roughness;\n    _7593 = param_3.occlusion;\n    _7594 = param_3.emission;\n    _7595 = param_3.clearcoat;\n    _7596 = param_3.clearcoat_roughness;\n    _7597 = param_3.sheen_color;\n    _7598 = param_3.sheen_roughness;\n    _7599 = param_3.anisotropy;\n    _7600 = param_3.anisotropy_rotation;\n    _7601 = param_3.specular;\n    _7602 = param_3.ior;\n    _7603 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _7557;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _7588 = param_6;\n    _7590 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _7588;\n    }\n    else\n    {\n        vec3 _6967 = normalize(_7590);\n        float _6974 = clamp(_7591, 0.0, 1.0);\n        float _6978 = clamp(_7592, 0.0500000007450580596923828125, 1.0);\n        float _6982 = _6978 * _6978;\n        float _6986 = _6982 * _6982;\n        float _6991 = max(dot(_6967, _6920), 9.9999997473787516355514526367188e-05);\n        vec3 _6997 = _7588 * (1.0 - _6974);\n        vec3 _7004 = mix(vec3(0.039999999105930328369140625), _7588, vec3(_6974));\n        vec3 f0 = _7004;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _7557, fa_world_tangent, fa_uv, fa_vertex_color, _6920, gl_FrontFacing);\n        Surface param_9 = Surface(_7588, _7589, _7590, _7591, _7592, _7593, _7594, _7595, _7596, _7597, _7598, _7599, _7600, _7601, _7602, _7603);\n        vec3 param_10 = _6967;\n        vec3 param_11 = _6920;\n        float param_12 = _6974;\n        float param_13 = _6978;\n        vec3 param_14 = _7004;\n        FaLayers _7020 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _6967;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _6997) * _7593;\n        if (_7020.on)\n        {\n            lit *= _7020.base_scale;\n        }\n        int _7042 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _7042; ln++)\n        {\n            int param_16 = ln;\n            int _7055 = fa_cl_light(param_16);\n            int param_17 = _7055;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _7055;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _7557;\n            LightSample _7071 = fa_light_shadowed(param_18, param_19, param_20);\n            float _7079 = max(dot(_6967, _7071.direction), 0.0);\n            float _7085 = _7071.attenuation * _7071.shadow;\n            vec3 _7090 = normalize(_7071.direction + _6920);\n            float _7095 = max(dot(_6967, _7090), 0.0);\n            float _7100 = max(dot(_6920, _7090), 0.0);\n            bool _7107;\n            if (fa_light_is_area)\n            {\n                _7107 = !_7020.on;\n            }\n            else\n            {\n                _7107 = fa_light_is_area;\n            }\n            if (_7107)\n            {\n                int param_21 = _7055;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _6967;\n                vec3 param_24 = _6920;\n                vec3 param_25 = _6997;\n                vec3 param_26 = f0;\n                float param_27 = 1.0;\n                float param_28 = _6978;\n                float param_29 = _6991;\n                float param_30 = _7085;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _7020;\n                    int param_32 = _7055;\n                    vec3 param_33 = fa_world_pos;\n                    vec3 param_34 = _6967;\n                    vec3 param_35 = _6920;\n                    vec3 param_36 = _7071.direction;\n                    vec3 param_37 = _6997;\n                    vec3 param_38 = f0;\n                    float param_39 = _6978;\n                    float param_40 = _6991;\n                    float param_41 = _7085;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_7020.on)\n                    {\n                        FaLayers param_42 = _7020;\n                        vec3 param_43 = _6997;\n                        vec3 param_44 = f0;\n                        vec3 param_45 = _6967;\n                        vec3 param_46 = _6920;\n                        vec3 param_47 = _7071.direction;\n                        vec3 param_48 = _7090;\n                        float param_49 = _7079;\n                        float param_50 = _6991;\n                        float param_51 = _7095;\n                        float param_52 = _7100;\n                        float param_53 = _6982;\n                        float param_54 = _6986;\n                        int param_55 = _7055;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _7085));\n                    }\n                    else\n                    {\n                        float _7213 = ((_7095 * _7095) * (_6986 - 1.0)) + 1.0;\n                        int param_56 = _7055;\n                        lit += (((_6997 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _7100, 5.0))) * (((_6986 / ((3.1415927410125732421875 * _7213) * _7213)) * (0.5 / max(mix((2.0 * _7079) * _6991, _7079 + _6991, _6982), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _7079))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_7079 * _7085));\n                    }\n                }\n            }\n        }\n        if (_7020.on)\n        {\n            FaLayers param_57 = _7020;\n            vec3 param_58 = _6967;\n            vec3 param_59 = _6920;\n            vec3 param_60 = f0;\n            float param_61 = _6978;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _7593);\n        }\n        else\n        {\n            vec3 param_62 = _6967;\n            vec3 param_63 = _6920;\n            vec3 param_64 = f0;\n            float param_65 = _6978;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _7593);\n        }\n        result = lit;\n    }\n    vec3 _7308 = result;\n    vec3 _7309 = _7308 + _7594;\n    result = _7309;\n    vec3 param_66 = _7309;\n    vec3 param_67 = fa_world_pos;\n    result = fa_shadow_debug(param_66, param_67);\n    bool _7318 = fa_mesh_fs_params[7].w > 0.0;\n    bool _7325;\n    if (!_7318)\n    {\n        _7325 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _7325 = _7318;\n    }\n    if (_7325)\n    {\n        vec3 _7334 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _7340 = dot(_7334, fa_mesh_fs_params[9].xyz);\n        bool _7344 = fa_mesh_fs_params[9].w > 0.5;\n        float _7345;\n        if (_7344)\n        {\n            _7345 = _7340;\n        }\n        else\n        {\n            _7345 = length(_7334);\n        }\n        float _7357 = _7345 - fa_mesh_fs_params[8].x;\n        if (_7357 > 0.0)\n        {\n            float _7366 = fa_mesh_fs_params[7].w * _7357;\n            float tau = _7366 * _7366;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _7382;\n                if (_7344)\n                {\n                    _7382 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _7340);\n                }\n                else\n                {\n                    _7382 = fa_mesh_fs_params[0].y;\n                }\n                float _7403 = mix(_7382, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _7345, 0.0, 1.0));\n                float _7407 = fa_world_pos.y - _7403;\n                float _7412 = _7403 - fa_mesh_fs_params[8].z;\n                float _7417 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _7420 = _7412 <= 0.0;\n                bool _7421 = !_7420;\n                bool _7427;\n                if (_7421)\n                {\n                    _7427 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7427 = _7420;\n                }\n                float _7428;\n                if (_7427)\n                {\n                    _7428 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _7428 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _7412, 80.0));\n                }\n                bool _7455;\n                if (_7421)\n                {\n                    _7455 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7455 = _7420;\n                }\n                float _7456;\n                if (_7455)\n                {\n                    _7456 = fa_mesh_fs_params[8].y * _7412;\n                }\n                else\n                {\n                    _7456 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _7412, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _7481 = _7417 <= 0.0;\n                bool _7488;\n                if (!_7481)\n                {\n                    _7488 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7488 = _7481;\n                }\n                float _7489;\n                if (_7488)\n                {\n                    _7489 = fa_mesh_fs_params[8].y * _7417;\n                }\n                else\n                {\n                    _7489 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _7417, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _7516;\n                if (abs(_7407) < 0.001000000047497451305389404296875)\n                {\n                    _7516 = _7428;\n                }\n                else\n                {\n                    _7516 = (_7489 - _7456) / _7407;\n                }\n                tau += (_7357 * max(_7516, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _7589);\n}\n\n",
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
            "size": 800,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_608",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 50,
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
            "inst_name": "_2275",
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
            "inst_name": "_6501",
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
              "name": "fa_probe_atlas",
              "multisampled": false,
              "type": "2d",
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
              "slot": 25,
              "stage": "fragment",
              "name": "fa_light_atlas",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
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
            "name": "fa_probe_atlas_fa_env_smp",
            "view_name": "fa_probe_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_probe_atlas_fa_env_smp"
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10,
            "glsl_name": "fa_light_atlas_fa_env_smp"
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          },
          {
            "slot": 11,
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4291[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[50];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 7) in vec3 fa_lm;\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1546 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1553;\n    if (!_1546)\n    {\n        _1553 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1553 = _1546;\n    }\n    bool _1561;\n    if (!_1553)\n    {\n        _1561 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1561 = _1553;\n    }\n    bool _1568;\n    if (!_1561)\n    {\n        _1568 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1568 = _1561;\n    }\n    bool _1575;\n    if (!_1568)\n    {\n        _1575 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1575 = _1568;\n    }\n    if (_1575)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1585 = vec4(world_pos, 1.0);\n    float _1591 = dot(fa_mesh_fs_params[16], _1585);\n    if (!(_1591 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1613 = vec2(dot(fa_mesh_fs_params[14], _1585), dot(fa_mesh_fs_params[15], _1585)) / vec2(_1591);\n    int _1617 = int(fa_mesh_fs_params[18].x);\n    int _1621 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1621) + clamp(int(floor(((_1613.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1621 - 1)) * _1617)) + clamp(int(floor(((_1613.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1617 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1697 = fa_cluster_texel(param);\n    return ivec2(int(_1697.x), int(_1697.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5389 = fa_cluster_lookup(param);\n    fa_cl_slot = _5389.x;\n    fa_cl_local = _5389.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _6553 = fa_linear_to_srgb(param);\n        c = _6553;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _6561 = fa_srgb_to_linear(param_1);\n            c = _6561;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _490;\n    if (i.front_facing)\n    {\n        _490 = i.world_normal;\n    }\n    else\n    {\n        _490 = -i.world_normal;\n    }\n    vec3 _514 = normalize(i.world_tangent.xyz - (_490 * dot(_490, i.world_tangent.xyz)));\n    vec3 _541 = normalize(((_514 * m.x) + ((cross(_490, _514) * i.world_tangent.w) * m.y)) + (_490 * m.z));\n    vec3 _544;\n    if (i.front_facing)\n    {\n        _544 = _541;\n    }\n    else\n    {\n        _544 = -_541;\n    }\n    return _544;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _6592 = fa_tex_fix(param_2, param_3);\n    vec4 _8077 = base_t;\n    _8077.x = _6592.x;\n    _8077.y = _6592.y;\n    _8077.z = _6592.z;\n    base_t = _8077;\n    vec4 _6606 = (_8077 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _7877 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _6638 = fa_tex_fix(param_6, param_7);\n        vec3 _6641 = (_6638 * 2.0) - vec3(1.0);\n        vec2 _6646 = _6641.xy * fa_mesh_fs_params[6].x;\n        vec3 _8085 = _6641;\n        _8085.x = _6646.x;\n        _8085.y = _6646.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _8085;\n        _7877 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _6674 = fa_tex_fix(param_12, param_13);\n    vec4 _8088 = mrt;\n    _8088.x = _6674.x;\n    _8088.y = _6674.y;\n    _8088.z = _6674.z;\n    mrt = _8088;\n    vec4 _6702 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _6702.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _6713 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _6743 = fa_tex_fix(param_20, param_21);\n    float _7882 = fa_mesh_fs_params[20].x;\n    float _7883 = fa_mesh_fs_params[20].y;\n    float _7886 = fa_mesh_fs_params[20].z;\n    float _7885 = fa_mesh_fs_params[21].w;\n    float _7888 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _7882 *= _6713.y;\n            _7883 *= _6713.z;\n            _7885 *= _6702.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _7886 *= mrt.x;\n            _7888 *= mrt.w;\n        }\n    }\n    return Surface(_6606.xyz, _6606.w, _7877, clamp(fa_mesh_fs_params[5].x * _6674.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _6674.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_6713.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _6743), _7882, _7883, fa_mesh_fs_params[21].xyz, _7885, _7886, fa_mesh_fs_params[20].w, _7888, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1777 = rect.zw - rect.xy;\n    vec2 _1781 = _1777 * atlas;\n    vec2 _1785 = ddx * _1781;\n    vec2 _1789 = ddy * _1781;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1777), clamp(0.5 * log2(max(max(dot(_1785, _1785), dot(_1789, _1789)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1822 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1829;\n    if (!_1822)\n    {\n        _1829 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1829 = _1822;\n    }\n    if (_1829)\n    {\n        return;\n    }\n    vec3 _1835 = dFdx(world_pos);\n    vec3 _1838 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1842 = fa_cluster_texel(param);\n    int _1846 = int(_1842.w);\n    if (_1846 < 1)\n    {\n        return;\n    }\n    int _1856 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1856;\n    vec4 _1860 = fa_light_texel(param_1);\n    vec2 _1863 = _1860.yz;\n    int _1867 = int(_1860.w);\n    int param_2 = _1856 + 1;\n    vec4 _1872 = fa_light_texel(param_2);\n    float _1873 = _1872.x;\n    int _1879 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1883 = int(_1842.z);\n    vec3 _2148;\n    for (int k = 0; k < _1846; k++)\n    {\n        int _1896 = _1883 + k;\n        int param_3 = _1867 + (_1896 >> 2);\n        int _1913 = (_1856 + 2) + (int(fa_light_texel(param_3)[_1896 & 3]) * 7);\n        int param_4 = _1913 + 6;\n        vec4 _1918 = fa_light_texel(param_4);\n        if (((int(_1918.w + 0.5) >> _1879) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1913;\n        vec4 _1933 = fa_light_texel(param_5);\n        int param_6 = _1913 + 1;\n        vec4 _1938 = fa_light_texel(param_6);\n        int param_7 = _1913 + 2;\n        vec4 _1943 = fa_light_texel(param_7);\n        vec3 _1946 = _1933.xyz;\n        float _1951 = dot(_1946, world_pos) + _1933.w;\n        vec3 _1953 = _1938.xyz;\n        float _1958 = dot(_1953, world_pos) + _1938.w;\n        vec3 _1960 = _1943.xyz;\n        float _1965 = dot(_1960, world_pos) + _1943.w;\n        bool _1970 = abs(_1951) > 0.5;\n        bool _1978;\n        if (!_1970)\n        {\n            _1978 = abs(_1958) > 0.5;\n        }\n        else\n        {\n            _1978 = _1970;\n        }\n        bool _1986;\n        if (!_1978)\n        {\n            _1986 = abs(_1965) > 0.5;\n        }\n        else\n        {\n            _1986 = _1978;\n        }\n        if (_1986)\n        {\n            continue;\n        }\n        float _2001 = clamp(dot(geo_normal, normalize(_1960)) * _1918.z, 0.0, 1.0);\n        if (_2001 <= 0.0)\n        {\n            continue;\n        }\n        float _2021 = (clamp((0.5 - abs(_1965)) * 10.0, 0.0, 1.0) * _2001) * _1918.x;\n        vec2 _2029 = vec2(_1951 + 0.5, 0.5 - _1958);\n        vec2 _2039 = vec2(dot(_1946, _1835), dot(_1953, _1835));\n        vec2 _2049 = vec2(dot(_1946, _1838), dot(_1953, _1838));\n        int param_8 = _1913 + 5;\n        vec4 _2054 = fa_light_texel(param_8);\n        int param_9 = _1913 + 3;\n        vec4 _2059 = fa_light_texel(param_9);\n        int param_10 = _1913 + 4;\n        vec4 _2064 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2054.xyz;\n        bool _2074 = _2059.z > _2059.x;\n        if (_2074)\n        {\n            vec4 param_11 = _2059;\n            vec2 param_12 = _2029;\n            vec2 param_13 = _1863;\n            vec2 param_14 = _2039;\n            vec2 param_15 = _2049;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1873 > 0.5) && (_1873 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2100 = fa_dc_to_linear(param_16);\n                vec4 _7957 = tx;\n                _7957.x = _2100.x;\n                _7957.y = _2100.y;\n                _7957.z = _2100.z;\n                tx = _7957;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2021 * tex_a) * _2054.w, 0.0, 1.0)));\n        if (_2064.z > _2064.x)\n        {\n            vec4 param_17 = _2064;\n            vec2 param_18 = _2029;\n            vec2 param_19 = _1863;\n            vec2 param_20 = _2039;\n            vec2 param_21 = _2049;\n            vec4 _2144 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1873 > 1.5)\n            {\n                vec3 param_22 = _2144.xyz;\n                vec3 _2154 = fa_dc_to_srgb(param_22);\n                _2148 = _2154;\n            }\n            else\n            {\n                _2148 = _2144.xyz;\n            }\n            vec3 _2163 = (_2148 * 2.0) - vec3(1.0);\n            vec2 _2168 = _2163.xy * _1918.y;\n            vec3 _2190 = (normalize(_1946) * _2168.x) + (normalize(_1953) * _2168.y);\n            vec3 _2193 = normalize(normal);\n            normal = normalize(mix(_2193, normalize((_2193 * max(_2163.z, 0.0500000007450580596923828125)) + (_2190 - (_2193 * dot(_2193, _2190)))), vec3(clamp(_2021 * (_2074 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4217 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4224 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4227 = int(_4217);\n    int _4230 = int(_4224);\n    float _4240 = _4224 - float(_4230);\n    int _4295 = (_4227 * 9) + _4230;\n    int _4315 = ((_4227 + 1) * 9) + _4230;\n    return mix(mix(_4291[_4295], _4291[_4295 + 1], _4240), mix(_4291[_4315], _4291[_4315 + 1], _4240), _4217 - float(_4227));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _7800 = false;\n    float _7801 = 1.0;\n    float _7802 = 1.0;\n    float _7803 = 1.0;\n    float _7804 = 0.0;\n    float _7805 = 0.0;\n    float _7806 = 0.0;\n    float _7807 = 0.0;\n    float _7809 = 1.0;\n    bool _7810 = false;\n    vec3 _7811 = vec3(0.0);\n    float _7812 = 1.0;\n    float _7813 = 1.0;\n    float _7814 = 1.0;\n    float _7815 = 0.0;\n    float _7816 = 0.0;\n    vec3 _7817 = vec3(1.0, 0.0, 0.0);\n    vec3 _7818 = vec3(0.0, 0.0, 1.0);\n    float _7819 = 1.0;\n    float _7820 = 1.0;\n    float _4366 = clamp(s.specular, 0.0, 1.0);\n    float _4370 = clamp(s.ior, 1.0, 3.0);\n    bool _4375 = (_4366 != 1.0) || (_4370 != 1.5);\n    bool _4384;\n    if (!_4375)\n    {\n        _4384 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4384 = _4375;\n    }\n    if (_4384)\n    {\n        float _4392 = (_4370 - 1.0) / (_4370 + 1.0);\n        f0 = mix(min(vec3(_4392 * _4392) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4366, s.albedo, vec3(metallic));\n        _7801 = mix(_4366, 1.0, metallic);\n        _7800 = true;\n    }\n    float _4419 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4419 > 0.0)\n    {\n        float _4427 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _7804 = _4419;\n        _7805 = _4427;\n        float _4434 = _4427 * _4427;\n        _7806 = _4434;\n        _7807 = _4434 * _4434;\n        float _4446 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _7809 = _4446;\n        _7802 = 1.0 - (_4419 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4446, 0.0, 1.0), 5.0))));\n        _7800 = true;\n    }\n    vec3 _4465 = max(s.sheen_color, vec3(0.0));\n    float _4474 = max(_4465.x, max(_4465.y, _4465.z));\n    if (_4474 > 0.0)\n    {\n        float _4482 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _7810 = true;\n        _7811 = _4465;\n        _7812 = _4482;\n        _7813 = _4482 * _4482;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4482;\n        float _4499 = fa_sheen_albedo(param, param_1);\n        _7815 = _4499;\n        _7814 = 1.0 - min(_4474 * _4499, 1.0);\n        _7800 = true;\n    }\n    _7803 = _7802 * _7814;\n    float _4518 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4518 != 0.0)\n    {\n        vec3 _4533 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4533;\n        if (dot(_4533, _4533) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4545 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4545.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4545.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4545.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4549 = t;\n        vec3 _4550 = normalize(_4549);\n        t = _4550;\n        vec3 _4575 = normalize((_4550 * cos(s.anisotropy_rotation)) + ((cross(n, _4550) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _7817 = _4575;\n        _7818 = cross(n, _4575);\n        float _4585 = roughness * roughness;\n        float _4591 = mix(_4585, 1.0, _4518 * _4518);\n        bool _4593 = _4518 > 0.0;\n        _7819 = _4593 ? _4591 : _4585;\n        _7820 = _4593 ? _4585 : _4591;\n        _7816 = _4518;\n        _7800 = true;\n    }\n    return FaLayers(_7800, _7801, _7802, _7803, _7804, _7805, _7806, _7807, i.world_normal, _7809, _7810, _7811, _7812, _7813, _7814, _7815, _7816, _7817, _7818, _7819, _7820);\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[39].y > 0.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3388 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3388;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _3998 = (1.0 - fa_mesh_fs_params[40].w) - fa_mesh_fs_params[45].w;\n    vec3 amb = vec3(0.0);\n    bool _4003 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_3998 > 0.0005000000237487256526947021484375)\n    {\n        if (_4003)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[39].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3998;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _3998;\n        }\n    }\n    bool _4054 = fa_mesh_fs_params[40].w > 0.0;\n    if (_4054)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[40].xy;\n            float param_4 = fa_mesh_fs_params[40].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[40].w);\n        }\n    }\n    bool _4085 = fa_mesh_fs_params[45].w > 0.0;\n    if (_4085)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[45].xy;\n            float param_7 = fa_mesh_fs_params[45].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[45].w);\n        }\n    }\n    if ((_4003 || _4054) || _4085)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[30].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 30].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[30].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5359;\n    if (fa_lm.z > 0.5)\n    {\n        _5359 = 0.0;\n    }\n    else\n    {\n        _5359 = 1.0 - clamp(fa_mesh_fs_params[30].w, 0.0, 1.0);\n    }\n    bool _5370 = _5359 < 1.0;\n    bool _5376;\n    if (_5370)\n    {\n        int param = li;\n        _5376 = fa_light_baked(param);\n    }\n    else\n    {\n        _5376 = _5370;\n    }\n    return _5376 ? _5359 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _795 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _808 = (c - (ru * hx)) - p;\n        vec3 _814 = ru * (2.0 * hx);\n        float _820 = max(dot(_814, _814), 9.9999999392252902907785028219223e-09);\n        float _824 = dot(_808, _814);\n        float t = clamp((-_824) / _820, 0.0, 1.0);\n        if (_795)\n        {\n            float _839 = dot(r, _814);\n            float _845 = _820 - (_839 * _839);\n            if (abs(_845) > (9.9999997473787516355514526367188e-06 * _820))\n            {\n                t = clamp(((dot(r, _808) * _839) - _824) / _845, 0.0, 1.0);\n            }\n        }\n        return (p + _808) + (_814 * t);\n    }\n    vec3 q = p;\n    float _877 = dot(r, axis);\n    bool _885;\n    if (_795)\n    {\n        _885 = abs(_877) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _885 = _795;\n    }\n    if (_885)\n    {\n        float _895 = dot(c - p, axis) / _877;\n        if (_895 > 0.0)\n        {\n            q = p + (r * _895);\n        }\n    }\n    vec3 _908 = q - c;\n    vec2 xy = vec2(dot(_908, ru), dot(_908, uu));\n    if (shape > 0.5)\n    {\n        float _923 = length(xy);\n        if (_923 > hx)\n        {\n            xy *= (hx / _923);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _556 = abs(d);\n    float _558 = _556.x;\n    float _560 = _556.y;\n    bool _561 = _558 >= _560;\n    bool _569;\n    if (_561)\n    {\n        _569 = _558 >= _556.z;\n    }\n    else\n    {\n        _569 = _561;\n    }\n    int _570;\n    if (_569)\n    {\n        _570 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _585;\n        if (_560 >= _556.z)\n        {\n            _585 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _585 = (d.z > 0.0) ? 4 : 5;\n        }\n        _570 = _585;\n    }\n    return _570;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _715 = dot(d, right);\n    float _719 = dot(d, up);\n    float _730;\n    if (((_715 * _715) + (_719 * _719)) > 1.0000000133514319600180897396058e-10)\n    {\n        _730 = atan(_719, _715) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _730 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_730 - floor(_730)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _961 = fa_light_base(param);\n    bool _965 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _961;\n    vec4 _969 = fa_light_texel(param_1);\n    int param_2 = _961 + 1;\n    vec4 _974 = fa_light_texel(param_2);\n    float _977 = _974.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _989 = _965 && (_977 > 2.5);\n    fa_light_is_area = _989;\n    bool _991 = _977 < 0.5;\n    vec3 l;\n    if (_991)\n    {\n        l = normalize(_969.xyz);\n        if (_965)\n        {\n            int param_3 = _961 + 6;\n            vec4 _1005 = fa_light_texel(param_3);\n            if (_1005.z > 0.5)\n            {\n                int param_4 = _961 + 4;\n                vec4 _1015 = fa_light_texel(param_4);\n                int param_5 = _961 + 5;\n                vec4 _1020 = fa_light_texel(param_5);\n                vec2 param_6 = _1005.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1015.xyz) * _1015.w, (-dot(world_pos, _1020.xyz)) * _1020.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1050 = _969.xyz;\n        vec3 _1052 = _1050 - world_pos;\n        vec3 to_light = _1052;\n        float _1055 = length(_1052);\n        float reach = _1055;\n        bool front = true;\n        if (_989)\n        {\n            int param_8 = _961 + 7;\n            reach = max(_1055 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _961 + 4;\n            vec4 _1079 = fa_light_texel(param_9);\n            int param_10 = _961 + 5;\n            vec4 _1084 = fa_light_texel(param_10);\n            int param_11 = _961 + 6;\n            vec4 _1089 = fa_light_texel(param_11);\n            float _1090 = _1089.w;\n            int param_12 = _961 + 2;\n            vec3 _1097 = normalize(fa_light_texel(param_12).xyz);\n            bool _1099 = _1090 > 1.5;\n            bool _1107;\n            if (!_1099)\n            {\n                _1107 = dot(_1097, to_light) < 0.0;\n            }\n            else\n            {\n                _1107 = _1099;\n            }\n            front = _1107;\n            vec3 r = vec3(0.0);\n            vec3 _1116 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1120 = dot(n, n) > 0.5;\n            bool _1128;\n            if (_1120)\n            {\n                _1128 = dot(_1116, _1116) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1128 = _1120;\n            }\n            if (_1128)\n            {\n                r = reflect(-normalize(_1116), normalize(n));\n            }\n            vec3 param_13 = _1050;\n            vec3 param_14 = _1097;\n            vec3 param_15 = _1079.xyz;\n            vec3 param_16 = _1084.xyz;\n            float param_17 = _1079.w;\n            float param_18 = _1084.w;\n            float param_19 = _1090;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1164 = length(to_light);\n        dist = _1164;\n        l = to_light / vec3(max(_1164, 9.9999997473787516355514526367188e-05));\n        float _1178 = reach / max(_969.w, 0.001000000047497451305389404296875);\n        float _1184 = clamp(1.0 - (_1178 * _1178), 0.0, 1.0);\n        float _1186;\n        if (front)\n        {\n            _1186 = _1184 * _1184;\n        }\n        else\n        {\n            _1186 = 0.0;\n        }\n        atten = _1186;\n        bool _1197 = _977 < 2.5;\n        if ((_977 > 1.5) && _1197)\n        {\n            int param_22 = _961 + 2;\n            vec4 _1205 = fa_light_texel(param_22);\n            float _1215 = _1205.w;\n            int param_23 = _961 + 3;\n            vec4 _1220 = fa_light_texel(param_23);\n            float _1221 = _1220.x;\n            float cos_inner = _1221;\n            if (_1221 > 1.5)\n            {\n                cos_inner = mix(_1215, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1215, cos_inner, dot(-l, normalize(_1205.xyz)));\n        }\n        if (_965 && (_977 < 1.5))\n        {\n            int param_24 = _961 + 6;\n            vec4 _1245 = fa_light_texel(param_24);\n            if (_1245.z > 0.5)\n            {\n                vec3 _1253 = -to_light;\n                int param_25 = _961 + 4;\n                int param_26 = _961 + 5;\n                vec3 _1267 = fa_light_texel(param_25).xyz;\n                vec3 _1271 = fa_light_texel(param_26).xyz;\n                vec3 _1280 = vec3(dot(_1253, _1267), dot(_1253, _1271), dot(_1253, cross(_1267, _1271)));\n                vec3 param_27 = _1280;\n                int _1284 = fa_cube_face(param_27);\n                int param_28 = _1284;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1311 = vec2(dot(_1280, cross(param_29, param_30)), dot(_1280, param_30)) / vec2(max(dot(_1280, param_29), 9.9999997473787516355514526367188e-05));\n                int _1315 = _1284 / 3;\n                vec2 param_31 = _1245.xy + (vec2(float(_1284 - (_1315 * 3)), float(_1315)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1311.x), 0.5 - (0.5 * _1311.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _961 + 7;\n            vec4 _1345 = fa_light_texel(param_33);\n            if (_1345.z > 0.5)\n            {\n                int param_34 = _961 + 2;\n                int param_35 = _961 + 4;\n                int param_36 = _961 + 5;\n                vec2 param_37 = _1345.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_965 && _1197)\n            {\n                int param_42 = _961 + 6;\n                vec4 _1392 = fa_light_texel(param_42);\n                int param_43 = _961 + 7;\n                vec4 _1397 = fa_light_texel(param_43);\n                bool _1400 = _1392.z > 0.5;\n                bool _1407;\n                if (!_1400)\n                {\n                    _1407 = _1397.z > 0.5;\n                }\n                else\n                {\n                    _1407 = _1400;\n                }\n                if (_1407)\n                {\n                    int param_44 = _961 + 2;\n                    vec4 _1414 = fa_light_texel(param_44);\n                    vec3 _1418 = normalize(_1414.xyz);\n                    int param_45 = _961 + 4;\n                    vec4 _1423 = fa_light_texel(param_45);\n                    int param_46 = _961 + 5;\n                    vec4 _1428 = fa_light_texel(param_46);\n                    if (_1400)\n                    {\n                        vec3 _1436 = -to_light;\n                        float _1443 = _1414.w;\n                        float _1459 = 0.5 / max(dot(_1436, _1418) * (sqrt(max(1.0 - (_1443 * _1443), 0.0)) / max(_1443, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1392.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1436, _1423.xyz) * _1459), 0.5 - (dot(_1436, _1428.xyz) * _1459));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1397.z > 0.5)\n                    {\n                        vec2 param_49 = _1397.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1418;\n                        vec3 param_52 = _1423.xyz;\n                        vec3 param_53 = _1428.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _7788 = _974.xyz * atten;\n    if (_965)\n    {\n        _7788 *= fa_light_tint;\n    }\n    int _1528;\n    if (_991)\n    {\n        _1528 = 0;\n    }\n    else\n    {\n        _1528 = ((_977 > 1.5) && (_977 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _7788, atten, 1.0, dist, _1528);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2265;\n    if (i == 0)\n    {\n        _2265 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2281;\n        if (i == 1)\n        {\n            _2281 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2289;\n            if (i == 2)\n            {\n                _2289 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2289 = fa_shadows[24].w;\n            }\n            _2281 = _2289;\n        }\n        _2265 = _2281;\n    }\n    return _2265;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2322 = fa_shadow_depth(param, param_1);\n    float _2326;\n    if (conv.x < 0.5)\n    {\n        _2326 = _2322;\n    }\n    else\n    {\n        _2326 = (conv.y * conv.z) / (conv.z - (_2322 * (conv.z - conv.y)));\n    }\n    return _2326;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2253 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2253), sin(_2253)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2372 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2381;\n        if (k < 0.0)\n        {\n            _2381 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2381 = k;\n        }\n        float _2401 = clamp((_2381 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2372;\n            vec2 _2420 = fa_shadow_vogel(param_3, param_4, param_5) * _2401;\n            vec2 param_6 = uv + (_2420 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2432 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2432 < (zr - (length(_2420) * plane)))\n            {\n                sum += _2432;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2458 = sum / cnt;\n        float _2468;\n        if (k < 0.0)\n        {\n            _2468 = (-k) / max(_2458, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2468 = k;\n        }\n        radius = clamp(((max(zr - _2458, 0.0) * unit) * _2468) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2490 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2490; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2490;\n        float param_11 = _2372;\n        vec2 _2509 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2509 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2509) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2490);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2551 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2556 = clamp(dot(n, l), 0.0, 1.0);\n    float _2562 = sqrt(1.0 - (_2556 * _2556));\n    float _2569 = min(_2562 / max(_2556, 0.20000000298023223876953125), 4.0);\n    float _2574;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2574 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2574 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2599 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2574 * _2562)), 1.0);\n    float _2606 = _2599.x;\n    bool _2609 = _2606 < fa_shadows[ci * 1 + 16].x;\n    bool _2618;\n    if (!_2609)\n    {\n        _2618 = _2606 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2618 = _2609;\n    }\n    bool _2627;\n    if (!_2618)\n    {\n        _2627 = _2599.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2627 = _2618;\n    }\n    bool _2636;\n    if (!_2627)\n    {\n        _2636 = _2599.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2636 = _2627;\n    }\n    bool _2643;\n    if (!_2636)\n    {\n        _2643 = _2599.z > 1.0;\n    }\n    else\n    {\n        _2643 = _2636;\n    }\n    if (_2643)\n    {\n        return -1.0;\n    }\n    float _2651;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2651 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2651 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2599.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2599.z - ((_2651 * (1.0 + (0.5 * _2569))) / _2551);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2551;\n    float param_5 = _2551 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2569, 3.0)) * 0.5) / _2551;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3029 = int(fa_shadows[25].x + 0.5);\n    if (_3029 < 1)\n    {\n        return 1.0;\n    }\n    float _3044 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3029 - 1;\n    if (_3044 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3056 = _3029 > 1;\n    bool _3063;\n    if (_3056)\n    {\n        _3063 = _3044 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3063 = _3056;\n    }\n    if (_3063)\n    {\n        ci = 1;\n    }\n    bool _3067 = _3029 > 2;\n    bool _3074;\n    if (_3067)\n    {\n        _3074 = _3044 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3074 = _3067;\n    }\n    if (_3074)\n    {\n        ci = 2;\n    }\n    bool _3078 = _3029 > 3;\n    bool _3085;\n    if (_3078)\n    {\n        _3085 = _3044 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3085 = _3078;\n    }\n    if (_3085)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _3029)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3111 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3111;\n        if (_3111 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _3136;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3136 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3136 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _3155 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3136, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _3166 = clamp((_3044 - (fa_shadow_split_at(param_7) - _3155)) / _3155, 0.0, 1.0);\n        if (_3166 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _3029)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _3187 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3187;\n                if (_3187 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _3166);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2709 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2716;\n    if (!_2709)\n    {\n        _2716 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2716 = _2709;\n    }\n    if (_2716)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2729 = fa_light_texel(param);\n    float _2730 = _2729.x;\n    if (_2730 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2739 = int(_2730 + 0.5);\n    int param_1 = _2739;\n    vec4 _2743 = fa_light_texel(param_1);\n    int param_2 = _2739 + 1;\n    vec4 _2748 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2751 = _2743.y;\n    if (_2751 > 0.0)\n    {\n        float _2768 = 1.0 - smoothstep(0.75 * _2751, _2751, length(world - fa_shadows[27].xyz));\n        fade = _2768;\n        if (_2768 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2743.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2792 = (_2739 + 2) + (face * 6);\n    int param_4 = _2792;\n    int param_5 = _2792 + 1;\n    int param_6 = _2792 + 3;\n    vec4 _2806 = fa_light_texel(param_6);\n    int param_7 = _2792 + 4;\n    vec4 _2811 = fa_light_texel(param_7);\n    int param_8 = _2792 + 5;\n    vec4 _2816 = fa_light_texel(param_8);\n    float _2828 = _2816.x * max(dot(_2806, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2833 = clamp(dot(n, l), 0.0, 1.0);\n    float _2856 = clamp(dot(n, _2806.xyz), -1.0, 1.0);\n    float _2875 = min(sqrt(1.0 - (_2856 * _2856)) / max(abs(dot(n, world - lpos)) / max(dot(_2806, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2878 = _2748.y;\n    float _2880;\n    if (_2878 > 0.0)\n    {\n        _2880 = _2878;\n    }\n    else\n    {\n        _2880 = 1.5 * _2828;\n    }\n    vec4 _2900 = vec4(world + (n * (_2880 * sqrt(1.0 - (_2833 * _2833)))), 1.0);\n    float _2904 = dot(_2806, _2900);\n    float _2907 = _2816.y;\n    if (_2904 < _2907)\n    {\n        return 1.0;\n    }\n    vec2 _2922 = vec2(dot(fa_light_texel(param_4), _2900), dot(fa_light_texel(param_5), _2900)) / vec2(_2904);\n    float _2924 = _2922.x;\n    bool _2927 = _2924 < _2811.x;\n    bool _2936;\n    if (!_2927)\n    {\n        _2936 = _2924 > _2811.z;\n    }\n    else\n    {\n        _2936 = _2927;\n    }\n    bool _2945;\n    if (!_2936)\n    {\n        _2945 = _2922.y < _2811.y;\n    }\n    else\n    {\n        _2945 = _2936;\n    }\n    bool _2954;\n    if (!_2945)\n    {\n        _2954 = _2922.y > _2811.w;\n    }\n    else\n    {\n        _2954 = _2945;\n    }\n    if (_2954)\n    {\n        return 1.0;\n    }\n    float _2960 = _2748.x;\n    float _2962;\n    if (_2960 > 0.0)\n    {\n        _2962 = _2960;\n    }\n    else\n    {\n        _2962 = 1.5 * _2828;\n    }\n    vec2 param_9 = _2922;\n    vec4 param_10 = _2811;\n    float param_11 = _2904 - (_2962 * (1.0 + (0.5 * _2875)));\n    float param_12 = _2828;\n    float param_13 = 1.0;\n    float param_14 = _2816.z * 0.25;\n    float param_15 = (_2828 * min(_2875, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2907, _2816.z);\n    int param_17 = int(_2743.z + 0.5);\n    float param_18 = _2743.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5103 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5110;\n    if (!_5103)\n    {\n        _5110 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5110 = _5103;\n    }\n    if (_5110)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5123 = fa_light_texel(param);\n    float _5124 = _5123.y;\n    float len = _5124;\n    if (_5124 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5136 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5146 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5136);\n    if (_5146 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5152 = len;\n    float _5155 = min(_5152, 0.89999997615814208984375 * dist);\n    len = _5155;\n    float _5160 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5136);\n    float _5165 = _5160 + (0.5 * _5155);\n    vec3 _5171 = world + (gn * _5160);\n    float _5173 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5237;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5188 = (float(k) + _5173) * 0.083333335816860198974609375;\n        vec3 _5196 = _5171 + (l * (_5188 * len));\n        vec4 _5202 = vec4(_5196, 1.0);\n        float _5208 = dot(fa_mesh_fs_params[28], _5202);\n        if (_5208 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5228 = vec2(dot(fa_mesh_fs_params[26], _5202), dot(fa_mesh_fs_params[27], _5202)) / vec2(_5208);\n        float _5232 = _5228.x * 0.5;\n        float _5233 = _5232 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5237 = (_5228.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5237 = 0.5 - (_5228.y * 0.5);\n        }\n        bool _5253 = _5233 < 0.0;\n        bool _5260;\n        if (!_5253)\n        {\n            _5260 = _5233 >= 1.0;\n        }\n        else\n        {\n            _5260 = _5253;\n        }\n        bool _5267;\n        if (!_5260)\n        {\n            _5267 = _5237 < 0.0;\n        }\n        else\n        {\n            _5267 = _5260;\n        }\n        bool _5274;\n        if (!_5267)\n        {\n            _5274 = _5237 >= 1.0;\n        }\n        else\n        {\n            _5274 = _5267;\n        }\n        if (_5274)\n        {\n            break;\n        }\n        vec4 _5293 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_5233, _5237) * fa_mesh_fs_params[24].zw), 0);\n        if (_5293.w < 0.5)\n        {\n            continue;\n        }\n        float _5312 = (dot(fa_mesh_fs_params[29].xyz, _5196) + fa_mesh_fs_params[29].w) - _5293.x;\n        if ((_5312 > _5160) && (_5312 < _5165))\n        {\n            occ = max(occ, (1.0 - (_5188 * _5188)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5233, 0.5 - _5232), min(_5237, 1.0 - _5237))));\n        }\n    }\n    return 1.0 - (occ * _5146);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _5415 = fa_baked_keep(param);\n    if (_5415 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5441 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _7857 = _5441.color;\n    float _7858 = _5441.attenuation;\n    float _7859 = _5441.shadow;\n    bool _5444 = _5441.type == 0;\n    if (_5444 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5441.direction;\n        float _5455 = fa_shadow_factor(param_5, param_6);\n        _7859 = _5455;\n        _7857 *= _5455;\n    }\n    else\n    {\n        bool _5466 = _5441.type != 0;\n        bool _5472;\n        if (_5466)\n        {\n            _5472 = _7858 > 0.0;\n        }\n        else\n        {\n            _5472 = _5466;\n        }\n        if (_5472)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5441.direction;\n            float _5491 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _7859 = _5491;\n            _7857 *= _5491;\n        }\n    }\n    bool _5501 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5507;\n    if (_5501)\n    {\n        _5507 = _7858 > 0.0;\n    }\n    else\n    {\n        _5507 = _5501;\n    }\n    if (_5507)\n    {\n        float _5514;\n        if (_5444)\n        {\n            _5514 = 1000000000.0;\n        }\n        else\n        {\n            _5514 = _5441._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5441.direction;\n        float param_18 = _5514;\n        float _5532 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _7859 *= _5532;\n        _7857 *= _5532;\n    }\n    float _5545 = _7858;\n    float _5546 = _5545 * _5415;\n    _7858 = _5546;\n    vec3 _5550 = _7857;\n    vec3 _5551 = _5550 * _5415;\n    _7857 = _5551;\n    return LightSample(_5441.direction, _5551, _5546, _7859, _5441._distance, _5441.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _5585 = v - (n * dot(v, n));\n    vec3 t = _5585;\n    float _5589 = dot(_5585, _5585);\n    float l2 = _5589;\n    if (_5589 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _5599;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _5599 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _5599 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _5599;\n        l2 = dot(_5599, _5599);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _5634 = dot(a, a);\n    float _5638 = dot(b, b);\n    if ((_5634 < 1.0000000195414813782625560981111e-24) || (_5638 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _5652 = a * inversesqrt(_5634);\n    vec3 _5657 = b * inversesqrt(_5638);\n    float _5661 = dot(_5652, _5657);\n    float _5664 = abs(_5661);\n    float g = (((((((((((0.0416471660137176513671875 * _5664) - 0.1924748718738555908203125) * _5664) + 0.4179156124591827392578125) * _5664) - 0.616057217121124267578125) * _5664) + 0.777722418308258056640625) * _5664) - 0.999542415142059326171875) * _5664) + 1.570791721343994140625;\n    if (_5661 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_5661 * _5661), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_5652, _5657) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _5721 = a.z > 0.0;\n    bool _5725 = b.z > 0.0;\n    if (_5721 && _5725)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_5721 != _5725)\n        {\n            vec3 _5760 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _5760.z = 0.0;\n            if (_5721)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _5760;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _5760;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _5760;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _5760;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _5809 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _5835 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _5861 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _5887 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _5809;\n    vec3 param_1 = _5835;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _5835;\n    vec3 param_7 = _5861;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _5861;\n    vec3 param_13 = _5887;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _5887;\n    vec3 param_19 = _5809;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nfloat fa_ltc_rect(vec4 abcd, vec3 center, vec3 ex, vec3 ey)\n{\n    vec4 param = abcd;\n    vec3 param_1 = (center - ex) - ey;\n    vec3 param_2 = (center + ex) - ey;\n    vec3 param_3 = (center + ex) + ey;\n    vec3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    if ((shape < 0.5) || (shape > 1.5))\n    {\n        vec4 param = m;\n        vec3 param_1 = pc;\n        vec3 param_2 = ex;\n        vec3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    vec3 _6037 = (pc + (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _6061 = (pc - (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _6077 = (pc - (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec4 param_4 = m;\n    vec3 param_5 = _6037;\n    vec3 param_6 = (pc + (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_7 = (pc - (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_8 = _6061;\n    vec4 param_9 = m;\n    vec3 param_10 = _6037;\n    vec3 param_11 = _6061;\n    vec3 param_12 = (pc - (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    vec3 param_13 = _6077;\n    vec4 param_14 = m;\n    vec3 param_15 = _6037;\n    vec3 param_16 = _6077;\n    vec3 param_17 = (pc + (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec3 param_18 = (pc + (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _6135 = fa_light_base(param);\n    int param_1 = _6135;\n    int param_2 = _6135 + 1;\n    int param_3 = _6135 + 2;\n    int param_4 = _6135 + 4;\n    vec4 _6157 = fa_light_texel(param_4);\n    int param_5 = _6135 + 5;\n    vec4 _6162 = fa_light_texel(param_5);\n    int param_6 = _6135 + 6;\n    vec4 _6167 = fa_light_texel(param_6);\n    float _6168 = _6167.w;\n    vec3 _6173 = fa_light_texel(param_1).xyz - world_pos;\n    bool _6175 = _6168 < 1.5;\n    bool _6182;\n    if (_6175)\n    {\n        _6182 = dot(normalize(fa_light_texel(param_3).xyz), _6173) >= 0.0;\n    }\n    else\n    {\n        _6182 = _6175;\n    }\n    if (_6182)\n    {\n        return vec3(0.0);\n    }\n    bool _6191 = (_6168 > 0.5) && _6175;\n    float _6195 = _6191 ? 1.0539000034332275390625 : 1.0;\n    vec3 _6198 = _6157.xyz;\n    float _6200 = _6157.w;\n    vec3 _6206 = _6162.xyz;\n    float _6208 = _6162.w;\n    vec3 up = _6206 * (_6208 * _6195);\n    float _6214;\n    if (_6191)\n    {\n        _6214 = (3.1415927410125732421875 * _6200) * _6200;\n    }\n    else\n    {\n        _6214 = (4.0 * _6200) * _6208;\n    }\n    if (_6168 > 1.5)\n    {\n        vec3 _6240 = cross(_6198, -_6173);\n        vec3 perp = _6240;\n        float _6244 = dot(_6240, _6240);\n        vec3 _6247;\n        if (_6244 > 1.0000000133514319600180897396058e-10)\n        {\n            _6247 = perp * inversesqrt(_6244);\n        }\n        else\n        {\n            _6247 = _6206;\n        }\n        perp = _6247;\n        up = _6247 * _6208;\n    }\n    float _6268 = max(_6214, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _6278 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _6278;\n    vec3 param_10 = n;\n    vec3 param_11 = _6173;\n    vec3 _6286 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_12 = _6278;\n    vec3 param_13 = n;\n    vec3 param_14 = _6198 * (_6200 * _6195);\n    vec3 _6294 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_15 = _6278;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    vec3 _6302 = fa_ltc_local(param_15, param_16, param_17);\n    vec4 param_18 = vec4(1.0, 0.0, 0.0, 1.0);\n    float param_19 = _6168;\n    vec3 param_20 = _6286;\n    vec3 param_21 = _6294;\n    vec3 param_22 = _6302;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    vec2 _6321 = fa_ltc_uv(param_23, param_24) * 64.0;\n    vec2 param_25 = _6321;\n    vec2 param_26 = _6321 + vec2(64.0, 0.0);\n    vec4 _6331 = fa_atlas_fetch(param_26);\n    vec4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _6168;\n    vec3 param_29 = _6286;\n    vec3 param_30 = _6294;\n    vec3 param_31 = _6302;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _6331.x) + ((vec3(f90) - f0) * _6331.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_6173, _6173)) + _6268) / _6268) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4840 = 1.0 / alpha;\n    return ((2.0 + _4840) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _4840)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _4875 = max(dot(L.nc, l), 0.0);\n    float _4881 = max(dot(L.nc, h), 0.0);\n    float _4890 = ((_4881 * _4881) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _4890) * _4890)) * (0.5 / max(mix((2.0 * _4875) * L.coat_ndv, _4875 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4875)) * _4875;\n}\n\nvec3 fa_area_layers(FaLayers L, int li, vec3 world_pos, vec3 n, vec3 v, vec3 l, vec3 diffuse_color, vec3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    vec3 param_2 = n;\n    vec3 param_3 = v;\n    vec3 param_4 = diffuse_color;\n    vec3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _6399;\n    if (L.sheen_on)\n    {\n        _6399 = L.sheen_scale;\n    }\n    else\n    {\n        _6399 = 1.0;\n    }\n    vec3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _6399);\n    vec3 _6412 = normalize(l + v);\n    int param_10 = li;\n    vec3 _6423 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _6432 = max(dot(n, l), 0.0);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _6412), 0.0);\n        float param_13 = _6432;\n        float param_14 = ndv;\n        result += ((L.sheen * _6423) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _6432)) * _6432) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_15 = L;\n        vec3 param_16 = l;\n        vec3 param_17 = _6412;\n        float param_18 = max(dot(v, _6412), 0.0);\n        result += (_6423 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4743 = tdh / at;\n    float _4747 = bdh / ab;\n    float _4759 = ((_4743 * _4743) + (_4747 * _4747)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _4759) * _4759);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4939 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5018 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _5018) * _5018);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _4939);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _4939));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4149 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4152 = _4149.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4152 * _4152, exp2((-9.27999973297119140625) * ndv)) * _4152) + _4149.y)) + _4149.zw;\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3408 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3411 = _3408.x;\n    float _3413 = _3408.z;\n    vec2 e = vec2(_3411, _3413);\n    if (_3408.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3413)) * ((_3411 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3411)) * ((_3413 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3460;\n    if (lv == 0)\n    {\n        _3460 = 0.0;\n    }\n    else\n    {\n        _3460 = res + 2.0;\n    }\n    float _3470;\n    if (lv == 0)\n    {\n        _3470 = 0.0;\n    }\n    else\n    {\n        _3470 = (res - (res / float(1 << (lv - 1)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3460, _3470)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3515;\n    if (res > 64.5)\n    {\n        _3515 = 5.0;\n    }\n    else\n    {\n        _3515 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3530 = clamp(rough, 0.0, 1.0) * (_3515 - 1.0);\n    int _3537 = int(min(floor(_3530), _3515 - 2.0));\n    float _3542 = _3530 - float(_3537);\n    vec3 param = d;\n    vec2 _3546 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3537;\n    vec2 param_4 = _3546;\n    vec3 _3556 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3542 < 0.00200000009499490261077880859375)\n    {\n        return _3556;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3537 + 1;\n    vec2 param_8 = _3546;\n    return mix(_3556, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3542));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3626 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3633 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3640 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3646 = dot(bx.xyz, d);\n    float _3650 = dot(by.xyz, d);\n    float _3654 = dot(bz.xyz, d);\n    float _3660;\n    if (_3646 > 9.9999999747524270787835121154785e-07)\n    {\n        _3660 = (1.0 - _3626) / _3646;\n    }\n    else\n    {\n        float _3674;\n        if (_3646 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3674 = ((-1.0) - _3626) / _3646;\n        }\n        else\n        {\n            _3674 = 1000000015047466219876688855040.0;\n        }\n        _3660 = _3674;\n    }\n    float tx = _3660;\n    float _3691;\n    if (_3650 > 9.9999999747524270787835121154785e-07)\n    {\n        _3691 = (1.0 - _3633) / _3650;\n    }\n    else\n    {\n        float _3704;\n        if (_3650 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3704 = ((-1.0) - _3633) / _3650;\n        }\n        else\n        {\n            _3704 = 1000000015047466219876688855040.0;\n        }\n        _3691 = _3704;\n    }\n    float ty = _3691;\n    float _3720;\n    if (_3654 > 9.9999999747524270787835121154785e-07)\n    {\n        _3720 = (1.0 - _3640) / _3654;\n    }\n    else\n    {\n        float _3733;\n        if (_3654 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3733 = ((-1.0) - _3640) / _3654;\n        }\n        else\n        {\n            _3733 = 1000000015047466219876688855040.0;\n        }\n        _3720 = _3733;\n    }\n    float _3745 = tx;\n    float _3748 = (_3745 > 0.0) ? _3745 : 1000000015047466219876688855040.0;\n    tx = _3748;\n    float _3749 = ty;\n    float _3752 = (_3749 > 0.0) ? _3749 : 1000000015047466219876688855040.0;\n    ty = _3752;\n    float _3762 = min(_3748, min(_3752, (_3720 > 0.0) ? _3720 : 1000000015047466219876688855040.0));\n    if (_3762 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _3778 = (fa_world_pos + (d * _3762)) - posw.xyz;\n    vec3 _3783;\n    if (dot(_3778, _3778) > 1.0000000133514319600180897396058e-10)\n    {\n        _3783 = normalize(_3778);\n    }\n    else\n    {\n        _3783 = d;\n    }\n    return _3783;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _3829 = (1.0 - fa_mesh_fs_params[40].w) - fa_mesh_fs_params[45].w;\n    vec3 outc = vec3(0.0);\n    if (_3829 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[39].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3858 = rough * rough;\n            float _3889 = 0.60000002384185791015625 * _3858;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3858)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3889, 0.0500000007450580596923828125 + _3889, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3858 * 0.60000002384185791015625));\n        }\n        outc = base * _3829;\n    }\n    if (fa_mesh_fs_params[40].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[40];\n        vec4 param_5 = fa_mesh_fs_params[41];\n        vec4 param_6 = fa_mesh_fs_params[42];\n        vec4 param_7 = fa_mesh_fs_params[43];\n        vec4 param_8 = fa_mesh_fs_params[44];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _3948 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_3948 * fa_mesh_fs_params[40].w);\n    }\n    if (fa_mesh_fs_params[45].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[45];\n        vec4 param_12 = fa_mesh_fs_params[46];\n        vec4 param_13 = fa_mesh_fs_params[47];\n        vec4 param_14 = fa_mesh_fs_params[48];\n        vec4 param_15 = fa_mesh_fs_params[49];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _3980 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_3980 * fa_mesh_fs_params[45].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4626;\n        if (L.aniso >= 0.0)\n        {\n            _4626 = L.b;\n        }\n        else\n        {\n            _4626 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4626, v), _4626), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4659 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4659.x) + (vec3(L.f90) * _4659.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4714 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4714.x) + _4714.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4191 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4191.x) + vec3(_4191.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3211 = int(fa_shadows[25].x + 0.5);\n    float _3221 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint_1 = vec3(0.3499999940395355224609375);\n    bool _3226 = _3211 > 0;\n    bool _3235;\n    if (_3226)\n    {\n        int param = _3211 - 1;\n        _3235 = _3221 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3235 = _3226;\n    }\n    if (_3235)\n    {\n        tint_1 = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3241 = _3211 > 1;\n        bool _3248;\n        if (_3241)\n        {\n            _3248 = _3221 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3248 = _3241;\n        }\n        if (_3248)\n        {\n            tint_1 = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3254 = _3211 > 2;\n        bool _3261;\n        if (_3254)\n        {\n            _3261 = _3221 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3261 = _3254;\n        }\n        if (_3261)\n        {\n            tint_1 = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3267 = _3211 > 3;\n        bool _3274;\n        if (_3267)\n        {\n            _3274 = _3221 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3274 = _3267;\n        }\n        if (_3274)\n        {\n            tint_1 = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint_1, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _7557 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _7557 = -_7557;\n    }\n    vec3 _6920 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _7557, fa_world_tangent, fa_uv, fa_vertex_color, _6920, gl_FrontFacing);\n    Surface _6928 = fa_standard_surface(param_1);\n    vec3 _7588 = _6928.albedo;\n    float _7589 = _6928.alpha;\n    vec3 _7590 = _6928.normal;\n    float _7591 = _6928.metallic;\n    float _7592 = _6928.roughness;\n    float _7593 = _6928.occlusion;\n    vec3 _7594 = _6928.emission;\n    float _7595 = _6928.clearcoat;\n    float _7596 = _6928.clearcoat_roughness;\n    vec3 _7597 = _6928.sheen_color;\n    float _7598 = _6928.sheen_roughness;\n    float _7599 = _6928.anisotropy;\n    float _7600 = _6928.anisotropy_rotation;\n    float _7601 = _6928.specular;\n    float _7602 = _6928.ior;\n    vec3 _7603 = _6928.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _7557, fa_world_tangent, fa_uv, fa_vertex_color, _6920, gl_FrontFacing);\n    Surface param_3 = _6928;\n    surface(param_2, param_3);\n    _7588 = param_3.albedo;\n    _7589 = param_3.alpha;\n    _7590 = param_3.normal;\n    _7591 = param_3.metallic;\n    _7592 = param_3.roughness;\n    _7593 = param_3.occlusion;\n    _7594 = param_3.emission;\n    _7595 = param_3.clearcoat;\n    _7596 = param_3.clearcoat_roughness;\n    _7597 = param_3.sheen_color;\n    _7598 = param_3.sheen_roughness;\n    _7599 = param_3.anisotropy;\n    _7600 = param_3.anisotropy_rotation;\n    _7601 = param_3.specular;\n    _7602 = param_3.ior;\n    _7603 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _7557;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _7588 = param_6;\n    _7590 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _7588;\n    }\n    else\n    {\n        vec3 _6967 = normalize(_7590);\n        float _6974 = clamp(_7591, 0.0, 1.0);\n        float _6978 = clamp(_7592, 0.0500000007450580596923828125, 1.0);\n        float _6982 = _6978 * _6978;\n        float _6986 = _6982 * _6982;\n        float _6991 = max(dot(_6967, _6920), 9.9999997473787516355514526367188e-05);\n        vec3 _6997 = _7588 * (1.0 - _6974);\n        vec3 _7004 = mix(vec3(0.039999999105930328369140625), _7588, vec3(_6974));\n        vec3 f0 = _7004;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _7557, fa_world_tangent, fa_uv, fa_vertex_color, _6920, gl_FrontFacing);\n        Surface param_9 = Surface(_7588, _7589, _7590, _7591, _7592, _7593, _7594, _7595, _7596, _7597, _7598, _7599, _7600, _7601, _7602, _7603);\n        vec3 param_10 = _6967;\n        vec3 param_11 = _6920;\n        float param_12 = _6974;\n        float param_13 = _6978;\n        vec3 param_14 = _7004;\n        FaLayers _7020 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _6967;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _6997) * _7593;\n        if (_7020.on)\n        {\n            lit *= _7020.base_scale;\n        }\n        int _7042 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _7042; ln++)\n        {\n            int param_16 = ln;\n            int _7055 = fa_cl_light(param_16);\n            int param_17 = _7055;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _7055;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _7557;\n            LightSample _7071 = fa_light_shadowed(param_18, param_19, param_20);\n            float _7079 = max(dot(_6967, _7071.direction), 0.0);\n            float _7085 = _7071.attenuation * _7071.shadow;\n            vec3 _7090 = normalize(_7071.direction + _6920);\n            float _7095 = max(dot(_6967, _7090), 0.0);\n            float _7100 = max(dot(_6920, _7090), 0.0);\n            bool _7107;\n            if (fa_light_is_area)\n            {\n                _7107 = !_7020.on;\n            }\n            else\n            {\n                _7107 = fa_light_is_area;\n            }\n            if (_7107)\n            {\n                int param_21 = _7055;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _6967;\n                vec3 param_24 = _6920;\n                vec3 param_25 = _6997;\n                vec3 param_26 = f0;\n                float param_27 = 1.0;\n                float param_28 = _6978;\n                float param_29 = _6991;\n                float param_30 = _7085;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _7020;\n                    int param_32 = _7055;\n                    vec3 param_33 = fa_world_pos;\n                    vec3 param_34 = _6967;\n                    vec3 param_35 = _6920;\n                    vec3 param_36 = _7071.direction;\n                    vec3 param_37 = _6997;\n                    vec3 param_38 = f0;\n                    float param_39 = _6978;\n                    float param_40 = _6991;\n                    float param_41 = _7085;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_7020.on)\n                    {\n                        FaLayers param_42 = _7020;\n                        vec3 param_43 = _6997;\n                        vec3 param_44 = f0;\n                        vec3 param_45 = _6967;\n                        vec3 param_46 = _6920;\n                        vec3 param_47 = _7071.direction;\n                        vec3 param_48 = _7090;\n                        float param_49 = _7079;\n                        float param_50 = _6991;\n                        float param_51 = _7095;\n                        float param_52 = _7100;\n                        float param_53 = _6982;\n                        float param_54 = _6986;\n                        int param_55 = _7055;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _7085));\n                    }\n                    else\n                    {\n                        float _7213 = ((_7095 * _7095) * (_6986 - 1.0)) + 1.0;\n                        int param_56 = _7055;\n                        lit += (((_6997 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _7100, 5.0))) * (((_6986 / ((3.1415927410125732421875 * _7213) * _7213)) * (0.5 / max(mix((2.0 * _7079) * _6991, _7079 + _6991, _6982), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _7079))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_7079 * _7085));\n                    }\n                }\n            }\n        }\n        if (_7020.on)\n        {\n            FaLayers param_57 = _7020;\n            vec3 param_58 = _6967;\n            vec3 param_59 = _6920;\n            vec3 param_60 = f0;\n            float param_61 = _6978;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _7593);\n        }\n        else\n        {\n            vec3 param_62 = _6967;\n            vec3 param_63 = _6920;\n            vec3 param_64 = f0;\n            float param_65 = _6978;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _7593);\n        }\n        result = lit;\n    }\n    vec3 _7308 = result;\n    vec3 _7309 = _7308 + _7594;\n    result = _7309;\n    vec3 param_66 = _7309;\n    vec3 param_67 = fa_world_pos;\n    result = fa_shadow_debug(param_66, param_67);\n    bool _7318 = fa_mesh_fs_params[7].w > 0.0;\n    bool _7325;\n    if (!_7318)\n    {\n        _7325 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _7325 = _7318;\n    }\n    if (_7325)\n    {\n        vec3 _7334 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _7340 = dot(_7334, fa_mesh_fs_params[9].xyz);\n        bool _7344 = fa_mesh_fs_params[9].w > 0.5;\n        float _7345;\n        if (_7344)\n        {\n            _7345 = _7340;\n        }\n        else\n        {\n            _7345 = length(_7334);\n        }\n        float _7357 = _7345 - fa_mesh_fs_params[8].x;\n        if (_7357 > 0.0)\n        {\n            float _7366 = fa_mesh_fs_params[7].w * _7357;\n            float tau = _7366 * _7366;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _7382;\n                if (_7344)\n                {\n                    _7382 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _7340);\n                }\n                else\n                {\n                    _7382 = fa_mesh_fs_params[0].y;\n                }\n                float _7403 = mix(_7382, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _7345, 0.0, 1.0));\n                float _7407 = fa_world_pos.y - _7403;\n                float _7412 = _7403 - fa_mesh_fs_params[8].z;\n                float _7417 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _7420 = _7412 <= 0.0;\n                bool _7421 = !_7420;\n                bool _7427;\n                if (_7421)\n                {\n                    _7427 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7427 = _7420;\n                }\n                float _7428;\n                if (_7427)\n                {\n                    _7428 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _7428 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _7412, 80.0));\n                }\n                bool _7455;\n                if (_7421)\n                {\n                    _7455 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7455 = _7420;\n                }\n                float _7456;\n                if (_7455)\n                {\n                    _7456 = fa_mesh_fs_params[8].y * _7412;\n                }\n                else\n                {\n                    _7456 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _7412, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _7481 = _7417 <= 0.0;\n                bool _7488;\n                if (!_7481)\n                {\n                    _7488 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7488 = _7481;\n                }\n                float _7489;\n                if (_7488)\n                {\n                    _7489 = fa_mesh_fs_params[8].y * _7417;\n                }\n                else\n                {\n                    _7489 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _7417, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _7516;\n                if (abs(_7407) < 0.001000000047497451305389404296875)\n                {\n                    _7516 = _7428;\n                }\n                else\n                {\n                    _7516 = (_7489 - _7456) / _7407;\n                }\n                tau += (_7357 * max(_7516, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _7589);\n}\n\n",
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
            "size": 800,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_608",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 50,
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
            "inst_name": "_2275",
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
            "inst_name": "_6501",
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
              "name": "fa_probe_atlas",
              "multisampled": false,
              "type": "2d",
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
              "slot": 25,
              "stage": "fragment",
              "name": "fa_light_atlas",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
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
            "name": "fa_probe_atlas_fa_env_smp",
            "view_name": "fa_probe_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_probe_atlas_fa_env_smp"
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10,
            "glsl_name": "fa_light_atlas_fa_env_smp"
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          },
          {
            "slot": 11,
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_material[1];\nuniform vec4 fa_mesh_fs_params[50];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 8) in vec3 fa_pre_r0;\nlayout(location = 9) in vec3 fa_pre_r1;\nlayout(location = 10) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 7) in float fa_pre_depth;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _63;\n    if (i.front_facing)\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    vec3 _87 = normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    vec3 _115 = normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    vec3 _118;\n    if (i.front_facing)\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _266 = fa_tex_fix(param_2, param_3);\n    vec4 _772 = base_t;\n    _772.x = _266.x;\n    _772.y = _266.y;\n    _772.z = _266.z;\n    base_t = _772;\n    vec4 _282 = (_772 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _735 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _315 = fa_tex_fix(param_6, param_7);\n        vec3 _319 = (_315 * 2.0) - vec3(1.0);\n        vec2 _324 = _319.xy * fa_mesh_fs_params[6].x;\n        vec3 _780 = _319;\n        _780.x = _324.x;\n        _780.y = _324.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _780;\n        _735 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _353 = fa_tex_fix(param_12, param_13);\n    vec4 _783 = mrt;\n    _783.x = _353.x;\n    _783.y = _353.y;\n    _783.z = _353.z;\n    mrt = _783;\n    vec4 _383 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _383.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _395 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _425 = fa_tex_fix(param_20, param_21);\n    float _740 = fa_mesh_fs_params[20].x;\n    float _741 = fa_mesh_fs_params[20].y;\n    float _744 = fa_mesh_fs_params[20].z;\n    float _743 = fa_mesh_fs_params[21].w;\n    float _746 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _740 *= _395.y;\n            _741 *= _395.z;\n            _743 *= _383.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _744 *= mrt.x;\n            _746 *= mrt.w;\n        }\n    }\n    return Surface(_282.xyz, _282.w, _735, clamp(fa_mesh_fs_params[5].x * _353.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _353.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_395.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _425), _740, _741, fa_mesh_fs_params[21].xyz, _743, _744, fa_mesh_fs_params[20].w, _746, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _646 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _646 = -_646;\n    }\n    vec3 _558 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _646, fa_world_tangent, fa_uv, fa_vertex_color, _558, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _646, fa_world_tangent, fa_uv, fa_vertex_color, _558, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _573 = normalize(param_2.normal);\n    vec3 _588 = normalize(vec3(dot(fa_pre_r0, _573), dot(fa_pre_r1, _573), dot(fa_pre_r2, _573)));\n    float _600 = _588.z;\n    vec2 e = _588.xy / vec2((abs(_588.x) + abs(_588.y)) + abs(_600));\n    if (_600 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 800,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_255",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 50,
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_material[1];\nuniform vec4 fa_mesh_fs_params[50];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 8) in vec3 fa_pre_r0;\nlayout(location = 9) in vec3 fa_pre_r1;\nlayout(location = 10) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 7) in float fa_pre_depth;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _63;\n    if (i.front_facing)\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    vec3 _87 = normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    vec3 _115 = normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    vec3 _118;\n    if (i.front_facing)\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _266 = fa_tex_fix(param_2, param_3);\n    vec4 _772 = base_t;\n    _772.x = _266.x;\n    _772.y = _266.y;\n    _772.z = _266.z;\n    base_t = _772;\n    vec4 _282 = (_772 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _735 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _315 = fa_tex_fix(param_6, param_7);\n        vec3 _319 = (_315 * 2.0) - vec3(1.0);\n        vec2 _324 = _319.xy * fa_mesh_fs_params[6].x;\n        vec3 _780 = _319;\n        _780.x = _324.x;\n        _780.y = _324.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _780;\n        _735 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _353 = fa_tex_fix(param_12, param_13);\n    vec4 _783 = mrt;\n    _783.x = _353.x;\n    _783.y = _353.y;\n    _783.z = _353.z;\n    mrt = _783;\n    vec4 _383 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _383.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _395 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _425 = fa_tex_fix(param_20, param_21);\n    float _740 = fa_mesh_fs_params[20].x;\n    float _741 = fa_mesh_fs_params[20].y;\n    float _744 = fa_mesh_fs_params[20].z;\n    float _743 = fa_mesh_fs_params[21].w;\n    float _746 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _740 *= _395.y;\n            _741 *= _395.z;\n            _743 *= _383.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _744 *= mrt.x;\n            _746 *= mrt.w;\n        }\n    }\n    return Surface(_282.xyz, _282.w, _735, clamp(fa_mesh_fs_params[5].x * _353.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _353.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_395.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _425), _740, _741, fa_mesh_fs_params[21].xyz, _743, _744, fa_mesh_fs_params[20].w, _746, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _646 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _646 = -_646;\n    }\n    vec3 _558 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _646, fa_world_tangent, fa_uv, fa_vertex_color, _558, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _646, fa_world_tangent, fa_uv, fa_vertex_color, _558, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _573 = normalize(param_2.normal);\n    vec3 _588 = normalize(vec3(dot(fa_pre_r0, _573), dot(fa_pre_r1, _573), dot(fa_pre_r2, _573)));\n    float _600 = _588.z;\n    vec2 e = _588.xy / vec2((abs(_588.x) + abs(_588.y)) + abs(_600));\n    if (_600 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 800,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_255",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 50,
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
