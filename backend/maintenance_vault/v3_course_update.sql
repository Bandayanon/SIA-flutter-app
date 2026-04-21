-- v3_course_update.sql
-- Major Database Overhaul for Version 3.0

SET FOREIGN_KEY_CHECKS = 0;

-- 1. Clear old course directory
TRUNCATE TABLE `riasec_courses`;

-- 2. Insert the 21 unique school courses with their specialized RIASEC mappings and detailed reasons
INSERT INTO `riasec_courses` (CourseName, CourseCode, RIASECCategory, Description, ExplanationTip) VALUES
('Bachelor of Science in Agriculture', 'BSAg', 'R', 'The study of plant and animal production, soil science, and agricultural management.', 
'This course leverages your Realistic nature through hands-on engagement with soil, plants, and livestock, perfectly suiting those who prefer practical, physical work in natural environments.'),

('Bachelor of Science in Pharmacy', 'BSPharm', 'I', 'Focuses on drug therapy, chemical compositions, and healthcare pharmaceutical services.', 
'This course appeals to your Investigative side by requiring meticulous scientific analysis and research, focusing on the chemistry and biology behind effective healthcare treatments.'),

('Bachelor of Science in Biology', 'BSBio', 'I', 'The scientific study of living organisms and their ecosystems.', 
'Your Investigative curiosity will thrive here as you explore the complexities of living organisms through scientific inquiry, laboratory experiments, and research.'),

('Bachelor of Science in Radiologic Technology', 'BSRadTech', 'I', 'Focuses on medical imaging technologies like X-rays and MRI for health diagnosis.', 
'This technical field utilizes your Investigative skills in medical imaging, combining scientific precision with advanced technology to assist in accurate health diagnosis.'),

('BS in Medical Technology/ Medical Laboratory Science', 'BSMT', 'I', 'Involves laboratory analysis of body fluids to detect and treat diseases.', 
'Perfect for Investigative profiles, this course involves precise lab work and biological analysis, turning your analytical skills into life-saving medical data.'),

('Bachelor of Science in Psychology', 'BSPsych', 'S', 'The scientific study of human behavior, mental processes, and research.', 
'Your Social inclinations are ideal for psychology, where the focus is on helping others navigate their mental well-being through professional counseling and behavioral understanding.'),

('Bachelor of Science in Social Work', 'BSSW', 'S', 'Focuses on social welfare, community development, and humanitarian aid.', 
'This path directs your Social drive toward meaningful community service and advocacy, empowering you to support vulnerable individuals and drive social change.'),

('Bachelor of Science in Accountancy', 'BSA', 'C', 'The systematic recording, analysis, and reporting of financial transactions.', 
'This course fits your Conventional profile by rewarding high attention to detail, structured financial reporting, and the systematic organization of complex fiscal data.'),

('Bachelor of Science in Management Accounting', 'BSMA', 'C', 'Focuses on internal financial reporting and business decision support.', 
'Your Conventional skills in data organization and planning will excel here, focusing on internal financial strategy and ensuring efficient business operations.'),

('Bachelor of Science in Business Administration', 'BSBA', 'E', 'Covers broad management, marketing, and business operation principles.', 
'This course empowers your Enterprising leadership, teaching you to manage teams, drive business growth, and navigate competitive economic environments.'),

('Bachelor of Science in Entrepreneurship', 'BSEntrep', 'E', 'Focuses on starting, managing, and innovating new business ventures.', 
'Your Enterprising spirit is perfectly applied here, providing the tools to innovate, build your own business, and take calculated risks in the marketplace.'),

('Bachelor of Science in Tourism Management', 'BSTM', 'E', 'Study of travel, destination management, and hospitality operations.', 
'This field uses your Enterprising personality to manage travel operations and deliver premium hospitality experiences in a dynamic, people-oriented industry.'),

('Bachelor of Science in Criminology', 'BSCrim', 'R', 'Scientific study of crime, criminal behavior, and law enforcement.', 
'Your Realistic preference for structure and physical activity aligns with law enforcement, focusing on safety, investigation, and the practical application of justice.'),

('Bachelor of Science in Civil Engineering', 'BSCE', 'R', 'Design and construction of infrastructure like buildings and bridges.', 
'This Realistic choice focuses on the hands-on design and construction of infrastructure, perfect for those who enjoy seeing their practical blueprints become reality.'),

('Bachelor of Science in Information Technology', 'BSIT', 'I', 'Focuses on computer systems, software development, and network management.', 
'Your Investigative logic is key in IT, where you will solve complex digital puzzles, develop software, and manage the technical systems that power the modern world.'),

('BS in Entertainment and Multimedia Computing', 'BSEMC', 'A', 'Focuses on digital arts, game development, and multimedia content.', 
'This Artistic path allows you to blend technology with creative expression, perfect for designing digital worlds, games, and engaging multimedia content.'),

('Bachelor of Science in Nursing', 'BSN', 'S', 'Prepares students for clinical patient care and community health services.', 
'Your Social nature is at the heart of nursing, where providing direct patient care and emotional support is the cornerstone of clinical excellence.'),

('Bachelor of Early Childhood Education', 'BECE', 'S', 'Focuses on teaching and guiding children during their early developmental years.', 
'This Social path utilizes your patience and empathy to shape the foundation of young minds during their most critical years of development.'),

('Bachelor of Elementary Education', 'BEEd', 'S', 'Prepares educators for teaching roles in primary and elementary levels.', 
'Your Social drive to teach and inspire others is perfectly suited for educating children, fostering a love for learning in a supportive classroom environment.'),

('Bachelor of Secondary Education', 'BSEd', 'S', 'Specialized teaching preparation for high school level education.', 
'This Social profession uses your communication skills to guide teenagers through complex subjects, playing a vital role in their academic and personal growth.'),

('Bachelor of Technical - Vocational Teacher Education', 'BTVTED', 'R', 'Focuses on teaching technical skills and vocational crafts.', 
'This Realistic teaching path combines your technical proficiency with a drive to share practical skills, preparing others for success in skilled vocational fields.');

SET FOREIGN_KEY_CHECKS = 1;
