{
  "format": "factoria.shader/1",
  "engine": "0.31.0",
  "template": "5dd0da916b10a9a6f999383491342fc1c21819329ed9afcc0f9d0e7d6522a261",
  "slang": "metal_macos",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 fa_shadow_pos [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _129)\n{\n    float3 _67 = cross(model[1].xyz, model[2].xyz);\n    float _73 = (dot(model[0].xyz, _67) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_67 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _73, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _73), texcoord0 * _129.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _129, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& fa_shadow_pos, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _158 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _129);\n    float3 _267 = _158.world_pos;\n    float4 _165 = float4(_267, 1.0);\n    fa_world_pos = _267;\n    fa_world_normal = _158.world_normal;\n    fa_world_tangent = _158.world_tangent;\n    fa_uv = _158.uv;\n    fa_vertex_color = _158.color;\n    fa_shadow_pos = _129.fa_light_vp * _165;\n    gl_Position = _129.fa_view_proj * _165;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _129 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _129, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_shadow_pos, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct fa_lights\n{\n    float4 fa_light_pos[32];\n    float4 fa_light_color[32];\n    float4 fa_light_dir[32];\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 fa_shadow_pos [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _196 = fa_linear_to_srgb(param);\n        c = _196;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _205 = fa_srgb_to_linear(param_1);\n            c = _205;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _73;\n    if (bool(i.front_facing))\n    {\n        _73 = i.world_normal;\n    }\n    else\n    {\n        _73 = -i.world_normal;\n    }\n    float3 _98 = fast::normalize(i.world_tangent.xyz - (_73 * dot(_73, i.world_tangent.xyz)));\n    float3 _126 = fast::normalize(((_98 * m.x) + ((cross(_73, _98) * i.world_tangent.w) * m.y)) + (_73 * m.z));\n    float3 _129;\n    if (bool(i.front_facing))\n    {\n        _129 = _126;\n    }\n    else\n    {\n        _129 = -_126;\n    }\n    return _129;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _237, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _237.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _249 = fa_tex_fix(param_2, param_3);\n    float4 _1153 = base_t;\n    _1153.x = _249.x;\n    _1153.y = _249.y;\n    _1153.z = _249.z;\n    base_t = _1153;\n    float4 _265 = (_1153 * _237.fa_base_color) * i.vertex_color;\n    float3 _1139 = i.world_normal;\n    if (_237.fa_maps.z > 0.5)\n    {\n        float param_4 = _237.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _299 = fa_tex_fix(param_6, param_7);\n        float3 _303 = (_299 * 2.0) - float3(1.0);\n        float2 _308 = _303.xy * _237.fa_maps.x;\n        float3 _1161 = _303;\n        _1161.x = _308.x;\n        _1161.y = _308.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _1161;\n        _1139 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _237.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _337 = fa_tex_fix(param_12, param_13);\n    float4 _1164 = mrt;\n    _1164.x = _337.x;\n    _1164.y = _337.y;\n    _1164.z = _337.z;\n    mrt = _1164;\n    float param_14 = _237.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _378 = fa_tex_fix(param_16, param_17);\n    float param_18 = _237.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _405 = fa_tex_fix(param_20, param_21);\n    return Surface{ _265.xyz, _265.w, _1139, fast::clamp(_237.fa_pbr.x * _337.z, 0.0, 1.0), fast::clamp(_237.fa_pbr.y * _337.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_237.fa_maps.y * (_378.x - 1.0)), _237.fa_emissive.xyz + (_237.fa_model_emissive.xyz * _405) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 ambient(thread const SurfaceInput& i, thread const Surface& s, thread const float3& ambientColor)\n{\n    return float3(0.0, ambientColor.y, 0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _237, thread float4& fa_shadow_pos, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp)\n{\n    if (_237.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    float3 _427 = fa_shadow_pos.xyz / float3(fa_shadow_pos.w);\n    float3 p = _427;\n    float2 suv = (_427.xy * 0.5) + float2(0.5);\n    if (_237.fa_counts.z > 0.5)\n    {\n        float3 _1172 = p;\n        _1172.z = (_1172.z * 0.5) + 0.5;\n        p = _1172;\n    }\n    else\n    {\n        float2 _1175 = suv;\n        _1175.y = 1.0 - _1175.y;\n        suv = _1175;\n    }\n    bool _454 = suv.x < 0.0;\n    bool _461;\n    if (!_454)\n    {\n        _461 = suv.x > 1.0;\n    }\n    else\n    {\n        _461 = _454;\n    }\n    bool _468;\n    if (!_461)\n    {\n        _468 = suv.y < 0.0;\n    }\n    else\n    {\n        _468 = _461;\n    }\n    bool _475;\n    if (!_468)\n    {\n        _475 = suv.y > 1.0;\n    }\n    else\n    {\n        _475 = _468;\n    }\n    bool _482;\n    if (!_475)\n    {\n        _482 = p.z > 1.0;\n    }\n    else\n    {\n        _482 = _475;\n    }\n    if (_482)\n    {\n        return 1.0;\n    }\n    float _496 = _237.fa_pbr.w * (1.0 + (2.0 * (1.0 - fast::clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _496) <= fa_shadow_tex.sample(fa_shadow_smp, (suv + (float2(float(ix), float(iy)) * _237.fa_counts.y)), level(0.0)).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _237 [[buffer(1)]], constant fa_lights& _660 [[buffer(2)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    float3 _1040 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1040 = -_1040;\n    }\n    float3 _591 = fast::normalize(_237.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _1040, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _591, short(gl_FrontFacing) };\n    Surface _596 = fa_standard_surface(param, fa_tex, fa_smp, _237, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _1079 = _596.albedo;\n    float _1080 = _596.alpha;\n    float3 _1081 = _596.normal;\n    float _1082 = _596.metallic;\n    float _1083 = _596.roughness;\n    float _1084 = _596.occlusion;\n    float3 _1085 = _596.emission;\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _1040, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _591, short(gl_FrontFacing) };\n    Surface param_2 = _596;\n    surface(param_1, param_2);\n    _1079 = param_2.albedo;\n    _1080 = param_2.alpha;\n    _1081 = param_2.normal;\n    _1082 = param_2.metallic;\n    _1083 = param_2.roughness;\n    _1084 = param_2.occlusion;\n    _1085 = param_2.emission;\n    float3 result;\n    if (_237.fa_emissive.w > 0.5)\n    {\n        result = _1079;\n    }\n    else\n    {\n        float3 _617 = _1081;\n        float3 _618 = fast::normalize(_617);\n        _1081 = _618;\n        SurfaceInput param_3 = SurfaceInput{ in.fa_world_pos, _1040, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _591, short(gl_FrontFacing) };\n        Surface param_4 = Surface{ _1079, _1080, _618, _1082, _1083, _1084, _1085 };\n        float3 param_5 = _237.fa_ambient.xyz;\n        float3 lit = ambient(param_3, param_4, param_5);\n        int _637 = int(_237.fa_counts.x);\n        float3 l;\n        int _770;\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _637)\n            {\n                break;\n            }\n            float atten = 1.0;\n            float dist = 0.0;\n            bool _667 = _660.fa_light_color[li].w < 0.5;\n            if (_667)\n            {\n                l = fast::normalize(_660.fa_light_pos[li].xyz);\n            }\n            else\n            {\n                float3 _684 = _660.fa_light_pos[li].xyz - in.fa_world_pos;\n                float _686 = length(_684);\n                dist = _686;\n                l = _684 / float3(fast::max(_686, 9.9999997473787516355514526367188e-05));\n                float _702 = _686 / fast::max(_660.fa_light_pos[li].w, 0.001000000047497451305389404296875);\n                float _708 = fast::clamp(1.0 - (_702 * _702), 0.0, 1.0);\n                atten = _708 * _708;\n                if (_660.fa_light_color[li].w > 1.5)\n                {\n                    atten *= smoothstep(_660.fa_light_dir[li].w, mix(_660.fa_light_dir[li].w, 1.0, 0.25), dot(-l, fast::normalize(_660.fa_light_dir[li].xyz)));\n                }\n            }\n            float shadow = 1.0;\n            if (_667 && (li == 0))\n            {\n                float3 param_6 = _1040;\n                float3 param_7 = l;\n                shadow = fa_shadow_factor(param_6, param_7, _237, in.fa_shadow_pos, fa_shadow_tex, fa_shadow_smp);\n            }\n            if (_667)\n            {\n                _770 = 0;\n            }\n            else\n            {\n                _770 = (_660.fa_light_color[li].w > 1.5) ? 2 : 1;\n            }\n            SurfaceInput param_8 = SurfaceInput{ in.fa_world_pos, _1040, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _591, short(gl_FrontFacing) };\n            Surface param_9 = Surface{ _1079, _1080, _1081, _1082, _1083, _1084, _1085 };\n            LightSample param_10 = LightSample{ l, _660.fa_light_color[li].xyz * (atten * shadow), atten, shadow, dist, _770 };\n            lit += light(param_8, param_9, param_10);\n        }\n        result = lit;\n    }\n    result += _1085;\n    bool _798 = _237.fa_fog.w > 0.0;\n    bool _806;\n    if (!_798)\n    {\n        _806 = _237.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _806 = _798;\n    }\n    if (_806)\n    {\n        float3 _815 = in.fa_world_pos - _237.fa_camera_pos.xyz;\n        float _822 = dot(_815, _237.fa_fog_c.xyz);\n        bool _826 = _237.fa_fog_c.w > 0.5;\n        float _827;\n        if (_826)\n        {\n            _827 = _822;\n        }\n        else\n        {\n            _827 = length(_815);\n        }\n        float _839 = _827 - _237.fa_fog_b.x;\n        if (_839 > 0.0)\n        {\n            float _848 = _237.fa_fog.w * _839;\n            float tau = _848 * _848;\n            if (_237.fa_fog_b.y > 0.0)\n            {\n                float _864;\n                if (_826)\n                {\n                    _864 = in.fa_world_pos.y - (_237.fa_fog_c.y * _822);\n                }\n                else\n                {\n                    _864 = _237.fa_camera_pos.y;\n                }\n                float _885 = mix(_864, in.fa_world_pos.y, fast::clamp(_237.fa_fog_b.x / _827, 0.0, 1.0));\n                float _889 = in.fa_world_pos.y - _885;\n                float _894 = _885 - _237.fa_fog_b.z;\n                float _899 = in.fa_world_pos.y - _237.fa_fog_b.z;\n                bool _902 = _894 <= 0.0;\n                bool _903 = !_902;\n                bool _909;\n                if (_903)\n                {\n                    _909 = _237.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _909 = _902;\n                }\n                float _910;\n                if (_909)\n                {\n                    _910 = _237.fa_fog_b.y;\n                }\n                else\n                {\n                    _910 = _237.fa_fog_b.y * exp(-fast::min(_237.fa_fog_b.w * _894, 80.0));\n                }\n                bool _937;\n                if (_903)\n                {\n                    _937 = _237.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _937 = _902;\n                }\n                float _938;\n                if (_937)\n                {\n                    _938 = _237.fa_fog_b.y * _894;\n                }\n                else\n                {\n                    _938 = (_237.fa_fog_b.y * (1.0 - exp(-fast::min(_237.fa_fog_b.w * _894, 80.0)))) / _237.fa_fog_b.w;\n                }\n                bool _963 = _899 <= 0.0;\n                bool _970;\n                if (!_963)\n                {\n                    _970 = _237.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _970 = _963;\n                }\n                float _971;\n                if (_970)\n                {\n                    _971 = _237.fa_fog_b.y * _899;\n                }\n                else\n                {\n                    _971 = (_237.fa_fog_b.y * (1.0 - exp(-fast::min(_237.fa_fog_b.w * _899, 80.0)))) / _237.fa_fog_b.w;\n                }\n                float _998;\n                if (abs(_889) < 0.001000000047497451305389404296875)\n                {\n                    _998 = _910;\n                }\n                else\n                {\n                    _998 = (_971 - _938) / _889;\n                }\n                tau += (_839 * fast::max(_998, 0.0));\n            }\n            result = mix(result, _237.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _1080);\n    return out;\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main0"
        },
        "fragment_func": {
          "entry_point": "main0"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_129",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_237",
            "msl_buffer_n": 1
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_660",
            "msl_buffer_n": 2
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
              "sample_type": "float",
              "msl_texture_n": 0
            }
          },
          {
            "texture": {
              "slot": 1,
              "stage": "fragment",
              "name": "fa_shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "msl_texture_n": 1
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 2
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 3
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 4
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 5
            }
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_shadow_smp",
            "sampler_type": "nonfiltering",
            "msl_sampler_n": 1
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
            "sampler_slot": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 fa_shadow_pos [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _181)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _172 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_181.fa_joint_rows[_172] * weights[i]);\n        r1 += (_181.fa_joint_rows[_172 + 1] * weights[i]);\n        r2 += (_181.fa_joint_rows[_172 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _134)\n{\n    float3 _72 = cross(model[1].xyz, model[2].xyz);\n    float _78 = (dot(model[0].xyz, _72) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_72 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _78, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _78), texcoord0 * _134.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _134, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& fa_shadow_pos, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _271 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _134);\n    float3 _388 = _271.world_pos;\n    float4 _278 = float4(_388, 1.0);\n    fa_world_pos = _388;\n    fa_world_normal = _271.world_normal;\n    fa_world_tangent = _271.world_tangent;\n    fa_uv = _271.uv;\n    fa_vertex_color = _271.color;\n    fa_shadow_pos = _134.fa_light_vp * _278;\n    gl_Position = _134.fa_view_proj * _278;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _134 [[buffer(0)]], constant fa_skin& _181 [[buffer(3)]])\n{\n    main0_out out = {};\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _181);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _134, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_shadow_pos, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct fa_lights\n{\n    float4 fa_light_pos[32];\n    float4 fa_light_color[32];\n    float4 fa_light_dir[32];\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 fa_shadow_pos [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _196 = fa_linear_to_srgb(param);\n        c = _196;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _205 = fa_srgb_to_linear(param_1);\n            c = _205;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _73;\n    if (bool(i.front_facing))\n    {\n        _73 = i.world_normal;\n    }\n    else\n    {\n        _73 = -i.world_normal;\n    }\n    float3 _98 = fast::normalize(i.world_tangent.xyz - (_73 * dot(_73, i.world_tangent.xyz)));\n    float3 _126 = fast::normalize(((_98 * m.x) + ((cross(_73, _98) * i.world_tangent.w) * m.y)) + (_73 * m.z));\n    float3 _129;\n    if (bool(i.front_facing))\n    {\n        _129 = _126;\n    }\n    else\n    {\n        _129 = -_126;\n    }\n    return _129;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _237, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _237.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _249 = fa_tex_fix(param_2, param_3);\n    float4 _1153 = base_t;\n    _1153.x = _249.x;\n    _1153.y = _249.y;\n    _1153.z = _249.z;\n    base_t = _1153;\n    float4 _265 = (_1153 * _237.fa_base_color) * i.vertex_color;\n    float3 _1139 = i.world_normal;\n    if (_237.fa_maps.z > 0.5)\n    {\n        float param_4 = _237.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _299 = fa_tex_fix(param_6, param_7);\n        float3 _303 = (_299 * 2.0) - float3(1.0);\n        float2 _308 = _303.xy * _237.fa_maps.x;\n        float3 _1161 = _303;\n        _1161.x = _308.x;\n        _1161.y = _308.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _1161;\n        _1139 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _237.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _337 = fa_tex_fix(param_12, param_13);\n    float4 _1164 = mrt;\n    _1164.x = _337.x;\n    _1164.y = _337.y;\n    _1164.z = _337.z;\n    mrt = _1164;\n    float param_14 = _237.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _378 = fa_tex_fix(param_16, param_17);\n    float param_18 = _237.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _405 = fa_tex_fix(param_20, param_21);\n    return Surface{ _265.xyz, _265.w, _1139, fast::clamp(_237.fa_pbr.x * _337.z, 0.0, 1.0), fast::clamp(_237.fa_pbr.y * _337.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_237.fa_maps.y * (_378.x - 1.0)), _237.fa_emissive.xyz + (_237.fa_model_emissive.xyz * _405) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 ambient(thread const SurfaceInput& i, thread const Surface& s, thread const float3& ambientColor)\n{\n    return float3(0.0, ambientColor.y, 0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _237, thread float4& fa_shadow_pos, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp)\n{\n    if (_237.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    float3 _427 = fa_shadow_pos.xyz / float3(fa_shadow_pos.w);\n    float3 p = _427;\n    float2 suv = (_427.xy * 0.5) + float2(0.5);\n    if (_237.fa_counts.z > 0.5)\n    {\n        float3 _1172 = p;\n        _1172.z = (_1172.z * 0.5) + 0.5;\n        p = _1172;\n    }\n    else\n    {\n        float2 _1175 = suv;\n        _1175.y = 1.0 - _1175.y;\n        suv = _1175;\n    }\n    bool _454 = suv.x < 0.0;\n    bool _461;\n    if (!_454)\n    {\n        _461 = suv.x > 1.0;\n    }\n    else\n    {\n        _461 = _454;\n    }\n    bool _468;\n    if (!_461)\n    {\n        _468 = suv.y < 0.0;\n    }\n    else\n    {\n        _468 = _461;\n    }\n    bool _475;\n    if (!_468)\n    {\n        _475 = suv.y > 1.0;\n    }\n    else\n    {\n        _475 = _468;\n    }\n    bool _482;\n    if (!_475)\n    {\n        _482 = p.z > 1.0;\n    }\n    else\n    {\n        _482 = _475;\n    }\n    if (_482)\n    {\n        return 1.0;\n    }\n    float _496 = _237.fa_pbr.w * (1.0 + (2.0 * (1.0 - fast::clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _496) <= fa_shadow_tex.sample(fa_shadow_smp, (suv + (float2(float(ix), float(iy)) * _237.fa_counts.y)), level(0.0)).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _237 [[buffer(1)]], constant fa_lights& _660 [[buffer(2)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    float3 _1040 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1040 = -_1040;\n    }\n    float3 _591 = fast::normalize(_237.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _1040, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _591, short(gl_FrontFacing) };\n    Surface _596 = fa_standard_surface(param, fa_tex, fa_smp, _237, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _1079 = _596.albedo;\n    float _1080 = _596.alpha;\n    float3 _1081 = _596.normal;\n    float _1082 = _596.metallic;\n    float _1083 = _596.roughness;\n    float _1084 = _596.occlusion;\n    float3 _1085 = _596.emission;\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _1040, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _591, short(gl_FrontFacing) };\n    Surface param_2 = _596;\n    surface(param_1, param_2);\n    _1079 = param_2.albedo;\n    _1080 = param_2.alpha;\n    _1081 = param_2.normal;\n    _1082 = param_2.metallic;\n    _1083 = param_2.roughness;\n    _1084 = param_2.occlusion;\n    _1085 = param_2.emission;\n    float3 result;\n    if (_237.fa_emissive.w > 0.5)\n    {\n        result = _1079;\n    }\n    else\n    {\n        float3 _617 = _1081;\n        float3 _618 = fast::normalize(_617);\n        _1081 = _618;\n        SurfaceInput param_3 = SurfaceInput{ in.fa_world_pos, _1040, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _591, short(gl_FrontFacing) };\n        Surface param_4 = Surface{ _1079, _1080, _618, _1082, _1083, _1084, _1085 };\n        float3 param_5 = _237.fa_ambient.xyz;\n        float3 lit = ambient(param_3, param_4, param_5);\n        int _637 = int(_237.fa_counts.x);\n        float3 l;\n        int _770;\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _637)\n            {\n                break;\n            }\n            float atten = 1.0;\n            float dist = 0.0;\n            bool _667 = _660.fa_light_color[li].w < 0.5;\n            if (_667)\n            {\n                l = fast::normalize(_660.fa_light_pos[li].xyz);\n            }\n            else\n            {\n                float3 _684 = _660.fa_light_pos[li].xyz - in.fa_world_pos;\n                float _686 = length(_684);\n                dist = _686;\n                l = _684 / float3(fast::max(_686, 9.9999997473787516355514526367188e-05));\n                float _702 = _686 / fast::max(_660.fa_light_pos[li].w, 0.001000000047497451305389404296875);\n                float _708 = fast::clamp(1.0 - (_702 * _702), 0.0, 1.0);\n                atten = _708 * _708;\n                if (_660.fa_light_color[li].w > 1.5)\n                {\n                    atten *= smoothstep(_660.fa_light_dir[li].w, mix(_660.fa_light_dir[li].w, 1.0, 0.25), dot(-l, fast::normalize(_660.fa_light_dir[li].xyz)));\n                }\n            }\n            float shadow = 1.0;\n            if (_667 && (li == 0))\n            {\n                float3 param_6 = _1040;\n                float3 param_7 = l;\n                shadow = fa_shadow_factor(param_6, param_7, _237, in.fa_shadow_pos, fa_shadow_tex, fa_shadow_smp);\n            }\n            if (_667)\n            {\n                _770 = 0;\n            }\n            else\n            {\n                _770 = (_660.fa_light_color[li].w > 1.5) ? 2 : 1;\n            }\n            SurfaceInput param_8 = SurfaceInput{ in.fa_world_pos, _1040, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _591, short(gl_FrontFacing) };\n            Surface param_9 = Surface{ _1079, _1080, _1081, _1082, _1083, _1084, _1085 };\n            LightSample param_10 = LightSample{ l, _660.fa_light_color[li].xyz * (atten * shadow), atten, shadow, dist, _770 };\n            lit += light(param_8, param_9, param_10);\n        }\n        result = lit;\n    }\n    result += _1085;\n    bool _798 = _237.fa_fog.w > 0.0;\n    bool _806;\n    if (!_798)\n    {\n        _806 = _237.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _806 = _798;\n    }\n    if (_806)\n    {\n        float3 _815 = in.fa_world_pos - _237.fa_camera_pos.xyz;\n        float _822 = dot(_815, _237.fa_fog_c.xyz);\n        bool _826 = _237.fa_fog_c.w > 0.5;\n        float _827;\n        if (_826)\n        {\n            _827 = _822;\n        }\n        else\n        {\n            _827 = length(_815);\n        }\n        float _839 = _827 - _237.fa_fog_b.x;\n        if (_839 > 0.0)\n        {\n            float _848 = _237.fa_fog.w * _839;\n            float tau = _848 * _848;\n            if (_237.fa_fog_b.y > 0.0)\n            {\n                float _864;\n                if (_826)\n                {\n                    _864 = in.fa_world_pos.y - (_237.fa_fog_c.y * _822);\n                }\n                else\n                {\n                    _864 = _237.fa_camera_pos.y;\n                }\n                float _885 = mix(_864, in.fa_world_pos.y, fast::clamp(_237.fa_fog_b.x / _827, 0.0, 1.0));\n                float _889 = in.fa_world_pos.y - _885;\n                float _894 = _885 - _237.fa_fog_b.z;\n                float _899 = in.fa_world_pos.y - _237.fa_fog_b.z;\n                bool _902 = _894 <= 0.0;\n                bool _903 = !_902;\n                bool _909;\n                if (_903)\n                {\n                    _909 = _237.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _909 = _902;\n                }\n                float _910;\n                if (_909)\n                {\n                    _910 = _237.fa_fog_b.y;\n                }\n                else\n                {\n                    _910 = _237.fa_fog_b.y * exp(-fast::min(_237.fa_fog_b.w * _894, 80.0));\n                }\n                bool _937;\n                if (_903)\n                {\n                    _937 = _237.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _937 = _902;\n                }\n                float _938;\n                if (_937)\n                {\n                    _938 = _237.fa_fog_b.y * _894;\n                }\n                else\n                {\n                    _938 = (_237.fa_fog_b.y * (1.0 - exp(-fast::min(_237.fa_fog_b.w * _894, 80.0)))) / _237.fa_fog_b.w;\n                }\n                bool _963 = _899 <= 0.0;\n                bool _970;\n                if (!_963)\n                {\n                    _970 = _237.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _970 = _963;\n                }\n                float _971;\n                if (_970)\n                {\n                    _971 = _237.fa_fog_b.y * _899;\n                }\n                else\n                {\n                    _971 = (_237.fa_fog_b.y * (1.0 - exp(-fast::min(_237.fa_fog_b.w * _899, 80.0)))) / _237.fa_fog_b.w;\n                }\n                float _998;\n                if (abs(_889) < 0.001000000047497451305389404296875)\n                {\n                    _998 = _910;\n                }\n                else\n                {\n                    _998 = (_971 - _938) / _889;\n                }\n                tau += (_839 * fast::max(_998, 0.0));\n            }\n            result = mix(result, _237.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _1080);\n    return out;\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main0"
        },
        "fragment_func": {
          "entry_point": "main0"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_134",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_181",
            "msl_buffer_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_237",
            "msl_buffer_n": 1
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_660",
            "msl_buffer_n": 2
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
              "sample_type": "float",
              "msl_texture_n": 0
            }
          },
          {
            "texture": {
              "slot": 1,
              "stage": "fragment",
              "name": "fa_shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "msl_texture_n": 1
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 2
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 3
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 4
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 5
            }
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_shadow_smp",
            "sampler_type": "nonfiltering",
            "msl_sampler_n": 1
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
            "sampler_slot": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          }
        ]
      }
    },
    "prepass": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _129)\n{\n    float3 _67 = cross(model[1].xyz, model[2].xyz);\n    float _73 = (dot(model[0].xyz, _67) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_67 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _73, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _73), texcoord0 * _129.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _129, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _158 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _129);\n    float3 _296 = _158.world_pos;\n    float4 _169 = float4(_296, 1.0);\n    fa_world_pos = _296;\n    fa_world_normal = _158.world_normal;\n    fa_world_tangent = _158.world_tangent;\n    fa_uv = _158.uv;\n    fa_vertex_color = _158.color;\n    fa_pre_depth = -(_129.fa_light_vp * _169).z;\n    fa_pre_r0 = float3(_129.fa_light_vp[0].x, _129.fa_light_vp[1].x, _129.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_129.fa_light_vp[0].y, _129.fa_light_vp[1].y, _129.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_129.fa_light_vp[0].z, _129.fa_light_vp[1].z, _129.fa_light_vp[2].z);\n    gl_Position = _129.fa_view_proj * _169;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _129 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, _129, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _170 = fa_linear_to_srgb(param);\n        c = _170;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _179 = fa_srgb_to_linear(param_1);\n            c = _179;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _54;\n    if (bool(i.front_facing))\n    {\n        _54 = i.world_normal;\n    }\n    else\n    {\n        _54 = -i.world_normal;\n    }\n    float3 _79 = fast::normalize(i.world_tangent.xyz - (_54 * dot(_54, i.world_tangent.xyz)));\n    float3 _107 = fast::normalize(((_79 * m.x) + ((cross(_54, _79) * i.world_tangent.w) * m.y)) + (_54 * m.z));\n    float3 _110;\n    if (bool(i.front_facing))\n    {\n        _110 = _107;\n    }\n    else\n    {\n        _110 = -_107;\n    }\n    return _110;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _211, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _211.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _223 = fa_tex_fix(param_2, param_3);\n    float4 _578 = base_t;\n    _578.x = _223.x;\n    _578.y = _223.y;\n    _578.z = _223.z;\n    base_t = _578;\n    float4 _239 = (_578 * _211.fa_base_color) * i.vertex_color;\n    float3 _559 = i.world_normal;\n    if (_211.fa_maps.z > 0.5)\n    {\n        float param_4 = _211.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _273 = fa_tex_fix(param_6, param_7);\n        float3 _277 = (_273 * 2.0) - float3(1.0);\n        float2 _282 = _277.xy * _211.fa_maps.x;\n        float3 _586 = _277;\n        _586.x = _282.x;\n        _586.y = _282.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _586;\n        _559 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _211.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _311 = fa_tex_fix(param_12, param_13);\n    float4 _589 = mrt;\n    _589.x = _311.x;\n    _589.y = _311.y;\n    _589.z = _311.z;\n    mrt = _589;\n    float param_14 = _211.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _352 = fa_tex_fix(param_16, param_17);\n    float param_18 = _211.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _379 = fa_tex_fix(param_20, param_21);\n    return Surface{ _239.xyz, _239.w, _559, fast::clamp(_211.fa_pbr.x * _311.z, 0.0, 1.0), fast::clamp(_211.fa_pbr.y * _311.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_211.fa_maps.y * (_352.x - 1.0)), _211.fa_emissive.xyz + (_211.fa_model_emissive.xyz * _379) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _211 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    float3 _506 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _506 = -_506;\n    }\n    float3 _424 = fast::normalize(_211.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _506, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _424, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _506, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _424, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _211, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _439 = fast::normalize(param_2.normal);\n    float3 _454 = fast::normalize(float3(dot(in.fa_pre_r0, _439), dot(in.fa_pre_r1, _439), dot(in.fa_pre_r2, _439)));\n    float _466 = _454.z;\n    float2 e = _454.xy / float2((abs(_454.x) + abs(_454.y)) + abs(_466));\n    if (_466 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main0"
        },
        "fragment_func": {
          "entry_point": "main0"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_129",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_211",
            "msl_buffer_n": 1
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
              "sample_type": "float",
              "msl_texture_n": 0
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 1
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 2
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 3
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 4
            }
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 0
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
            "sampler_slot": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0
          }
        ]
      }
    },
    "prepass_skin": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _181)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _172 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_181.fa_joint_rows[_172] * weights[i]);\n        r1 += (_181.fa_joint_rows[_172 + 1] * weights[i]);\n        r2 += (_181.fa_joint_rows[_172 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _134)\n{\n    float3 _72 = cross(model[1].xyz, model[2].xyz);\n    float _78 = (dot(model[0].xyz, _72) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_72 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _78, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _78), texcoord0 * _134.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _134, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _271 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _134);\n    float3 _417 = _271.world_pos;\n    float4 _282 = float4(_417, 1.0);\n    fa_world_pos = _417;\n    fa_world_normal = _271.world_normal;\n    fa_world_tangent = _271.world_tangent;\n    fa_uv = _271.uv;\n    fa_vertex_color = _271.color;\n    fa_pre_depth = -(_134.fa_light_vp * _282).z;\n    fa_pre_r0 = float3(_134.fa_light_vp[0].x, _134.fa_light_vp[1].x, _134.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_134.fa_light_vp[0].y, _134.fa_light_vp[1].y, _134.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_134.fa_light_vp[0].z, _134.fa_light_vp[1].z, _134.fa_light_vp[2].z);\n    gl_Position = _134.fa_view_proj * _282;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _134 [[buffer(0)]], constant fa_skin& _181 [[buffer(3)]])\n{\n    main0_out out = {};\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _181);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _134, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _170 = fa_linear_to_srgb(param);\n        c = _170;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _179 = fa_srgb_to_linear(param_1);\n            c = _179;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _54;\n    if (bool(i.front_facing))\n    {\n        _54 = i.world_normal;\n    }\n    else\n    {\n        _54 = -i.world_normal;\n    }\n    float3 _79 = fast::normalize(i.world_tangent.xyz - (_54 * dot(_54, i.world_tangent.xyz)));\n    float3 _107 = fast::normalize(((_79 * m.x) + ((cross(_54, _79) * i.world_tangent.w) * m.y)) + (_54 * m.z));\n    float3 _110;\n    if (bool(i.front_facing))\n    {\n        _110 = _107;\n    }\n    else\n    {\n        _110 = -_107;\n    }\n    return _110;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _211, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _211.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _223 = fa_tex_fix(param_2, param_3);\n    float4 _578 = base_t;\n    _578.x = _223.x;\n    _578.y = _223.y;\n    _578.z = _223.z;\n    base_t = _578;\n    float4 _239 = (_578 * _211.fa_base_color) * i.vertex_color;\n    float3 _559 = i.world_normal;\n    if (_211.fa_maps.z > 0.5)\n    {\n        float param_4 = _211.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _273 = fa_tex_fix(param_6, param_7);\n        float3 _277 = (_273 * 2.0) - float3(1.0);\n        float2 _282 = _277.xy * _211.fa_maps.x;\n        float3 _586 = _277;\n        _586.x = _282.x;\n        _586.y = _282.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _586;\n        _559 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _211.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _311 = fa_tex_fix(param_12, param_13);\n    float4 _589 = mrt;\n    _589.x = _311.x;\n    _589.y = _311.y;\n    _589.z = _311.z;\n    mrt = _589;\n    float param_14 = _211.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _352 = fa_tex_fix(param_16, param_17);\n    float param_18 = _211.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _379 = fa_tex_fix(param_20, param_21);\n    return Surface{ _239.xyz, _239.w, _559, fast::clamp(_211.fa_pbr.x * _311.z, 0.0, 1.0), fast::clamp(_211.fa_pbr.y * _311.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_211.fa_maps.y * (_352.x - 1.0)), _211.fa_emissive.xyz + (_211.fa_model_emissive.xyz * _379) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _211 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    float3 _506 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _506 = -_506;\n    }\n    float3 _424 = fast::normalize(_211.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _506, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _424, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _506, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _424, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _211, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _439 = fast::normalize(param_2.normal);\n    float3 _454 = fast::normalize(float3(dot(in.fa_pre_r0, _439), dot(in.fa_pre_r1, _439), dot(in.fa_pre_r2, _439)));\n    float _466 = _454.z;\n    float2 e = _454.xy / float2((abs(_454.x) + abs(_454.y)) + abs(_466));\n    if (_466 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main0"
        },
        "fragment_func": {
          "entry_point": "main0"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_134",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_181",
            "msl_buffer_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_211",
            "msl_buffer_n": 1
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
              "sample_type": "float",
              "msl_texture_n": 0
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 1
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 2
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 3
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 4
            }
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 0
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
            "sampler_slot": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0
          }
        ]
      }
    }
  }
}
