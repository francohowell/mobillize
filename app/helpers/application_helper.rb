module ApplicationHelper

    def is_active_controller(controller_name, class_name = nil)
        if params[:controller] == controller_name
          class_name == nil ? "active" : class_name
        else
          nil
        end
    end

    def is_active_action(action_name)
        params[:action] == action_name ? "active" : nil
    end

    def is_active_section(controller_name, action_name)
      if is_active_controller(controller_name) && is_active_action(action_name)
        return "active"
      else
        nil
      end
    end

    def asset_exists?(subdirectory, filename)
      File.exists?(File.join(Rails.root, 'app', 'assets', subdirectory, filename))
    end

    def image_exists?(image)
      asset_exists?('images', image)
    end

    def javascript_exists?(script)
      extensions = %w(.coffee .erb .coffee.erb) + [""]
      extensions.inject(false) do |truth, extension|
        truth || asset_exists?('javascripts', "#{script}.js#{extension}")
      end
    end

    def stylesheet_exists?(stylesheet)
      extensions = %w(.scss .erb .scss.erb) + [""]
      extensions.inject(false) do |truth, extension|
        truth || asset_exists?('stylesheets', "#{stylesheet}.css#{extension}")
      end
    end

    def industries
      [
        "Aerospace",
        "Transportation",
        "Computers",
        "Telecommunication",
        "Agriculture",
        "Construction",
        "Education",
        "Pharmaceutical",
        "Food",
        "Health Care",
        "Hospitality",
        "Entertainment",
        "News Media",
        "Energy",
        "Manufacturing",
        "Music",
        "Services",
        "Political",
        "NonProfit",
        "Other"
      ]
    end

    def industry_sizes
      [
        "0-10",
        "10-20",
        "20-50",
        "50-100",
        "100+"
      ]
    end

    # Approved plans in the system. This can included private and public plans and they are intended to help weed out grandfathered accounts. 
    def approved_plans 
      return ["Pay As You Go", "Demo", "Retroactive", "Manual", "Bronze", "Silver", "Gold", "Diamond", "Platinum", "Plus", "Pro", "Ultra", "Elite", "Enterprise"]
    end

    # Plans that are allowed and do not require billing details.
    def excluded_payment_plans
      return ["Demo", "Retroactive", "Manual", "CheckPlan", "Unlimited"]
    end

    def excluded_organization_ids
      return [227, 230, 1747, 90, 337, 34, 89, 32, 86, 974, 2492, 297, 299, 58, 288, 75, 63, 105, 53, 69, 19, 94, 72, 61, 55, 73, 108, 109, 228, 232, 235, 238, 253, 338, 269, 244, 283, 282, 121, 284, 275, 292, 285, 266, 300, 302, 341, 473, 256, 304, 291, 267, 894, 901, 2112, 250, 753, 329, 308, 320, 977, 287, 167, 233, 239, 242, 248, 289, 295, 301, 293, 303, 305, 198, 352, 202, 203, 979, 980, 476, 2113, 978, 294, 311, 370, 309, 335, 987, 984, 354, 944, 933, 374, 683, 355, 87, 243, 496, 382, 383, 913, 914, 848, 850, 985, 460, 465, 658, 853, 918, 1867, 596, 915, 967, 992, 1013, 1007, 1015, 1023, 1037, 1136, 1043, 1044, 1273, 1131, 1093, 1754, 1869, 1061, 1063, 1185, 1067, 1068, 1069, 1194, 1071, 1072, 1074, 1070, 1075, 1077, 1078, 1080, 1082, 1085, 1165, 1167, 1168, 1170, 1171, 1172, 1175, 1176, 229, 1181, 1188, 1118, 1119, 1120, 1121, 1124, 1126, 2496, 1220, 2500, 1228, 1231, 1232, 1245, 1252, 1872, 1873, 1688, 1762, 1313, 1332, 1337, 1356, 1459, 1362, 1376, 1678, 2550, 2578, 1682, 1684, 2580, 1883, 1485, 1515, 1771, 2510, 1666, 2007, 1672, 1676, 1680, 1690, 1692, 1694, 1696, 1698, 1701, 2008, 1776, 2506, 1670, 1138, 1713, 1714, 2372, 1716, 2247, 1892, 1719, 2444, 1783, 1894, 1895, 2015, 2016, 2133, 2249, 1728, 1732, 2508, 2136, 1792, 2516, 2551, 2622, 1908, 2261, 2626, 2631, 1655, 1179, 2633, 1686, 2646, 2037, 1707, 1919, 2267, 2669, 2156, 1818, 2045, 1820, 1928, 1745, 1930, 2047, 2513, 2163, 2276, 2514, 2167, 2055, 2562, 1834, 2563, 1837, 1838, 2059, 1842, 2567, 2063, 2569, 2288, 2289, 2574, 2408, 2576, 1960, 2583, 1964, 2078, 2585, 2300, 2302, 2588, 2305, 1973, 2306, 2590, 1977, 2199, 2592, 2092, 1982, 1984, 2425, 2426, 2427, 1988, 2598, 2518, 2101, 2102, 2520, 2320, 2522, 2524, 2435, 2526, 2218, 2530, 2532, 2224, 2536, 2334, 2446, 2448, 2538, 2450, 2341, 2452, 2343, 2542, 2455, 2456, 2544, 2458, 2460, 2546, 2547, 2463, 2464, 2466, 2467, 2469, 2553, 2471, 2473, 2555, 2475, 2479, 2559, 2481, 2483, 2485, 2487, 2488, 2490, 2529, 2595, 2596, 2627, 2658, 2540, 2572, 2600, 2602, 2604, 2606, 2608, 2612, 2618, 21, 2634, 2636, 2638, 2640, 2643, 2644, 2648, 2650, 2654, 2655, 2657, 2660, 2662, 2665, 2666, 2668, 2671]
    end


end
